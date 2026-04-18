#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/build-dmg.sh <version>
# Example: ./scripts/build-dmg.sh 1.0.7

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
    echo "Usage: $0 <version>" >&2
    exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$REPO_ROOT/.build"
RELEASE_DIR="$BUILD_DIR/release"
STAGING_DIR="$BUILD_DIR/dmg-staging"
# Display name uses a space ("Notch Cove.app"); DMG filename keeps no space for URL-friendliness.
APP_NAME="Notch Cove"
BINARY_NAME="CodeIsland"
APP_DIR="$STAGING_DIR/${APP_NAME}.app"
CONTENTS_DIR="$APP_DIR/Contents"
OUTPUT_DMG="$BUILD_DIR/NotchCove.dmg"

echo "==> Building ${APP_NAME} ${VERSION} (universal)"

# Build for both architectures
cd "$REPO_ROOT"
swift build -c release --arch arm64
swift build -c release --arch x86_64

ARM_DIR="$BUILD_DIR/arm64-apple-macosx/release"
X86_DIR="$BUILD_DIR/x86_64-apple-macosx/release"

echo "==> Assembling .app bundle"

# Clean and recreate staging
rm -rf "$STAGING_DIR"
mkdir -p "$CONTENTS_DIR/MacOS"
mkdir -p "$CONTENTS_DIR/Helpers"
mkdir -p "$CONTENTS_DIR/Resources"

# Create universal binaries — internal executable name stays "CodeIsland" to
# match CFBundleExecutable in Info.plist and keep existing user data intact.
lipo -create "$ARM_DIR/${BINARY_NAME}" "$X86_DIR/${BINARY_NAME}" \
     -output "$CONTENTS_DIR/MacOS/${BINARY_NAME}"
lipo -create "$ARM_DIR/codeisland-bridge" "$X86_DIR/codeisland-bridge" \
     -output "$CONTENTS_DIR/Helpers/codeisland-bridge"

# Write Info.plist (use the root Info.plist as base, update version)
CURRENT_VER=$(defaults read "$REPO_ROOT/Info.plist" CFBundleShortVersionString)
sed -e "s/<string>${CURRENT_VER}<\/string>/<string>${VERSION}<\/string>/g" \
    "$REPO_ROOT/Info.plist" > "$CONTENTS_DIR/Info.plist"

# Compile app icon and asset catalog (AppIcon.appiconset lives inside Assets.xcassets).
xcrun actool \
    --output-format human-readable-text \
    --notices --warnings --errors \
    --platform macosx \
    --target-device mac \
    --minimum-deployment-target 14.0 \
    --app-icon AppIcon \
    --output-partial-info-plist /dev/null \
    --compile "$CONTENTS_DIR/Resources" \
    "$REPO_ROOT/Assets.xcassets"

# Copy SPM resource bundles into Contents/Resources/ — putting them at the .app
# root breaks Developer ID signing with "unsealed contents present in the bundle
# root". Bundle.module already checks resourceURL, so this layout loads fine.
for bundle in "$BUILD_DIR"/*/release/*.bundle; do
    if [ -e "$bundle" ]; then
        cp -R "$bundle" "$CONTENTS_DIR/Resources/"
        break
    fi
done

echo "==> App bundle assembled at $APP_DIR"

# ---------------------------------------------------------------------------
# Developer ID signing. Skippable via SKIP_SIGN=1 for local dev builds.
# Override the identity with SIGN_IDENTITY=... if you have a different cert.
# ---------------------------------------------------------------------------
# Sign the bundle. Priority:
#   1. SKIP_SIGN=1 or SIGN_IDENTITY="-"  → ad-hoc (for local dev / CI without cert)
#   2. SIGN_IDENTITY="<Developer ID name>" that matches keychain → Developer ID
#   3. Auto-detect first "Developer ID Application" cert in keychain
#   4. Fallback → ad-hoc (still runnable after user bypasses Gatekeeper)
ADHOC=0
if [ "${SKIP_SIGN:-0}" = "1" ] || [ "${SIGN_IDENTITY:-}" = "-" ]; then
    ADHOC=1
elif [ -n "${SIGN_IDENTITY:-}" ] && security find-identity -v -p codesigning | grep -q "$(printf '%s' "$SIGN_IDENTITY" | sed 's/[][\\.^$*/]/\\&/g')"; then
    :
elif security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
    SIGN_IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | sed 's/.*"\(.*\)".*/\1/')
else
    ADHOC=1
fi

if [ "$ADHOC" = "1" ]; then
    echo "==> Signing ad-hoc (no Developer ID) — users will need to bypass Gatekeeper on first launch"
    codesign --deep --force --sign - "$APP_DIR"
else
    echo "==> Signing with '$SIGN_IDENTITY'"
    codesign --deep --force --options runtime \
        --entitlements "$REPO_ROOT/CodeIsland.entitlements" \
        --sign "$SIGN_IDENTITY" \
        "$APP_DIR"
fi

echo "==> Creating DMG"

# Remove previous DMG if exists
rm -f "$OUTPUT_DMG"

create-dmg \
    --volname "${APP_NAME} ${VERSION}" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "${APP_NAME}.app" 175 190 \
    --hide-extension "${APP_NAME}.app" \
    --app-drop-link 425 190 \
    --no-internet-enable \
    "$OUTPUT_DMG" \
    "$STAGING_DIR/"

# ---------------------------------------------------------------------------
# Notarize + staple. Uses the "CodeIsland" keychain profile by default
# (xcrun notarytool store-credentials CodeIsland ...). Skippable via
# SKIP_NOTARIZE=1 for local dev builds. Override with NOTARY_PROFILE=....
# ---------------------------------------------------------------------------
NOTARY_PROFILE="${NOTARY_PROFILE:-Notch Cove}"
if [ "${SKIP_NOTARIZE:-0}" = "1" ]; then
    echo "==> SKIP_NOTARIZE=1 — release DMG is not notarized"
elif [ "$ADHOC" = "1" ]; then
    echo "==> Skipping notarization (ad-hoc signed; Apple only accepts Developer ID)"
else
    echo "==> Submitting to Apple notary service (profile '$NOTARY_PROFILE')"
    if xcrun notarytool submit "$OUTPUT_DMG" \
        --keychain-profile "$NOTARY_PROFILE" \
        --wait; then
        xcrun stapler staple "$OUTPUT_DMG"
    else
        echo "==> Notarization failed — inspect the log above and, if missing, run:"
        echo "    xcrun notarytool store-credentials \"$NOTARY_PROFILE\" --apple-id <id> --team-id <team> --password <app-specific>"
        exit 1
    fi
fi

echo "==> Done: $OUTPUT_DMG"
