import SwiftUI
import CodeIslandCore

/// Clawd — Claude mascot, adapted from clawd-on-desk SVG pixel art.
/// Renders SVG rects proportionally via Canvas + TimelineView animations.
struct ClawdView: View {
    let status: AgentStatus
    var size: CGFloat = 27
    @State private var alive = false
    @Environment(\.mascotSpeed) private var speed
    @AppStorage(SettingsKey.clawdCurlCycleMs) private var curlCycleMs = SettingsDefaults.clawdCurlCycleMs
    @AppStorage(SettingsKey.clawdCurlArmRaise) private var curlArmRaise = SettingsDefaults.clawdCurlArmRaise
    @AppStorage(SettingsKey.clawdCurlSway) private var curlSway = SettingsDefaults.clawdCurlSway
    @AppStorage(SettingsKey.clawdDumbbellSize) private var dumbbellSize = SettingsDefaults.clawdDumbbellSize
    private static let dumbbellC = Color(hex: "#40D5A6")

    // Colors from clawd-on-desk
    private static let bodyC  = Color(red: 0.871, green: 0.533, blue: 0.427) // #DE886D — face / body
    private static let armC   = Color(red: 0.788, green: 0.459, blue: 0.353) // #C9755A — slightly darker for arms
    private static let eyeC   = Color.black
    private static let alertC = Color(red: 1.0, green: 0.24, blue: 0.0)     // #FF3D00
    private static let kbBase = Color(red: 0.38, green: 0.44, blue: 0.50)  // lighter base
    private static let kbKey  = Color(red: 0.60, green: 0.66, blue: 0.72)  // visible keys
    private static let kbHi   = Color.white                                 // bright flash

    var body: some View {
        ZStack {
            switch status {
            case .idle:                 sleepScene
            case .processing, .running: workScene
            case .waitingApproval, .waitingQuestion: alertScene
            }
        }
        .frame(width: size, height: size)
        .clipped()
        .onAppear { alive = true }
        .onChange(of: status) {
            alive = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { alive = true }
        }
    }

    // ── Coordinate helper: maps SVG units to view points ──
    private struct V {
        let ox: CGFloat, oy: CGFloat, s: CGFloat
        let y0: CGFloat

        init(_ sz: CGSize, svgW: CGFloat = 15, svgH: CGFloat = 10, svgX0: CGFloat = 0, svgY0: CGFloat = 6) {
            s = min(sz.width / svgW, sz.height / svgH)
            ox = (sz.width - svgW * s) / 2 + svgX0 * s
            oy = (sz.height - svgH * s) / 2
            y0 = svgY0
        }
        func r(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, dy: CGFloat = 0) -> CGRect {
            CGRect(x: ox + x * s, y: oy + (y - y0 + dy) * s, width: w * s, height: h * s)
        }
    }

    // ── Rotated arm: returns polygon path for a rect rotated around pivot ──
    private func armPath(_ v: V, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat,
                         pivotX: CGFloat, pivotY: CGFloat, angle: CGFloat, dy: CGFloat) -> Path {
        let a = angle * .pi / 180
        let ca = cos(a), sa = sin(a)
        let corners: [(CGFloat, CGFloat)] = [
            (x - pivotX, y - pivotY),
            (x + w - pivotX, y - pivotY),
            (x + w - pivotX, y + h - pivotY),
            (x - pivotX, y + h - pivotY),
        ]
        var path = Path()
        for (i, (cx, cy)) in corners.enumerated() {
            let rx = cx * ca - cy * sa + pivotX
            let ry = cx * sa + cy * ca + pivotY
            let pt = CGPoint(x: v.ox + rx * v.s, y: v.oy + (ry - v.y0 + dy) * v.s)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Draw sleeping character (sploot pose from clawd-sleeping.svg)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    private func drawSleeping(_ ctx: GraphicsContext, v: V, breathe: CGFloat) {
        // Shadow (wider for sploot, pulses with breath)
        let shadowScale: CGFloat = 1.0 + breathe * 0.03
        ctx.fill(Path(v.r(-1, 15, 17 * shadowScale, 1)),
                 with: .color(.black.opacity(0.35 + breathe * 0.08)))

        // Legs pointing up from behind (wider 1×2 blocks for visibility)
        for x: CGFloat in [3, 5, 9, 11] {
            ctx.fill(Path(v.r(x, 8.5, 1, 1.5)), with: .color(Self.bodyC))
        }

        // Flattened torso — big puff on inhale (25% from SVG)
        let puff = max(0, breathe) * 0.25
        let torsoH: CGFloat = 5 * (1.0 + puff)
        let torsoY: CGFloat = 15 - torsoH
        let torsoW: CGFloat = 13 * (1.0 + breathe * 0.015) // slight width pulse
        let torsoX: CGFloat = 1 - (torsoW - 13) / 2
        ctx.fill(Path(v.r(torsoX, torsoY, torsoW, torsoH)), with: .color(Self.bodyC))

        // Arms spread flat on the ground
        ctx.fill(Path(v.r(-1, 13, 2, 2)), with: .color(Self.bodyC))
        ctx.fill(Path(v.r(14, 13, 2, 2)), with: .color(Self.bodyC))

        // Shut eyes (thicker for visibility, move with puff)
        let eyeY: CGFloat = 12.2 - puff * 2.5
        ctx.fill(Path(v.r(3, eyeY, 2.5, 1.0)), with: .color(Self.eyeC))
        ctx.fill(Path(v.r(9.5, eyeY, 2.5, 1.0)), with: .color(Self.eyeC))
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // SLEEP — sploot pose, breathing, floating z's
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    private var sleepScene: some View {
        ZStack {
            // Character body (behind)
            TimelineView(.periodic(from: .now, by: 0.06)) { ctx in
                sleepCanvas(t: ctx.date.timeIntervalSinceReferenceDate * speed)
            }

            // Z's — continuous float-up loop, staggered timing
            TimelineView(.periodic(from: .now, by: 0.05)) { ctx in
                let t = ctx.date.timeIntervalSinceReferenceDate * speed
                floatingZs(t: t)
            }
        }
    }

    private func floatingZs(t: Double) -> some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                floatingZ(t: t, index: i)
            }
        }
    }

    private func floatingZ(t: Double, index: Int) -> some View {
        let ci = Double(index)
        let cycle = 2.8 + ci * 0.3
        let delay = ci * 0.9
        let phase = ((t - delay).truncatingRemainder(dividingBy: cycle)) / cycle
        let p = max(0, phase)
        let fontSize = max(6, size * CGFloat(0.18 + p * 0.10))
        let baseOpacity = 0.7 - ci * 0.1
        let opacity = p < 0.8 ? baseOpacity : (1.0 - p) * 3.5 * baseOpacity
        let xOff = size * CGFloat(0.08 + ci * 0.06 + sin(p * .pi * 2) * 0.03)
        let yOff = -size * CGFloat(0.15 + p * 0.38)
        return Text("z")
            .font(.system(size: fontSize, weight: .black, design: .monospaced))
            .foregroundStyle(.white.opacity(opacity))
            .offset(x: xOff, y: yOff)
    }

    private func sleepCanvas(t: Double) -> some View {
        let phase = t.truncatingRemainder(dividingBy: 4.5) / 4.5
        let breathe: CGFloat = phase < 0.4 ? sin(phase / 0.4 * .pi) : 0

        return Canvas { c, sz in
            let v = V(sz, svgW: 17, svgH: 7, svgY0: 9)
            drawSleeping(c, v: v, breathe: breathe)
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // WORK — alternating dumbbell curls
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    private var workScene: some View {
        TimelineView(.periodic(from: .now, by: 0.03)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate * speed
            workCanvas(t: t)
        }
    }

    private func workCanvas(t: Double) -> some View {
        // Alternating curls — duration is Mascot Lab tunable
        let cycle: Double = Double(curlCycleMs) / 1000.0
        let leftRaw = sin(t * 2 * .pi / cycle)             // -1..1
        let rightRaw = sin(t * 2 * .pi / cycle + .pi)      // 180° out of phase
        let leftRaise: CGFloat = (leftRaw + 1) / 2          // 0..1
        let rightRaise: CGFloat = (rightRaw + 1) / 2

        // Body leans slightly toward the raised side (counter-weight look)
        let sway = CGFloat(leftRaw - rightRaw) * CGFloat(curlSway)
        let breathe = (leftRaise + rightRaise - 1) * 0.5    // puffs when either arm up

        // Eye blink
        let blinkPhase = t.truncatingRemainder(dividingBy: 3.2)
        let eyeH: CGFloat = (blinkPhase > 1.4 && blinkPhase < 1.55) ? 0.2 : 1.6

        return Canvas { c, sz in
            // Wider virtual canvas + X shift so outstretched dumbbells stay inside the frame
            let v = V(sz, svgW: 18, svgH: 11, svgX0: 1, svgY0: 4.8)

            // Shadow
            c.fill(Path(v.r(3, 15, 9, 1)), with: .color(.black.opacity(0.32)))

            // Legs
            for x: CGFloat in [3, 5, 9, 11] {
                c.fill(Path(v.r(x, 13, 1, 2)), with: .color(Self.bodyC))
            }

            // Arms + dumbbells first — the body is drawn on top so arms & weights
            // appear to pass behind the torso / face
            drawCurl(c, v: v, shoulderX: 1.5 + sway, raise: leftRaise)
            drawCurl(c, v: v, shoulderX: 13.5 + sway, raise: rightRaise)

            // Torso (full body, covers anything behind it)
            let bScale = 1.0 + breathe * 0.03
            let torsoW = 11 * bScale
            let torsoX = 2 - (torsoW - 11) / 2 + sway
            c.fill(Path(v.r(torsoX, 6, torsoW, 7)), with: .color(Self.bodyC))

            // Eyes — on top of the body
            let eyeY = 8 + (1.6 - eyeH) / 2
            c.fill(Path(v.r(4.3 + sway, eyeY, 1, eyeH)), with: .color(Self.eyeC))
            c.fill(Path(v.r(9.7 + sway, eyeY, 1, eyeH)), with: .color(Self.eyeC))
        }
    }

    private func drawCurl(_ c: GraphicsContext, v: V, shoulderX: CGFloat, raise: CGFloat) {
        let shoulderY: CGFloat = 9
        let fistY: CGFloat = 12 - raise * CGFloat(curlArmRaise)
        let top = min(shoulderY, fistY)
        let armH = abs(shoulderY - fistY) + 1.7
        // Arm (slightly darker than body)
        c.fill(Path(v.r(shoulderX, top, 1.2, armH)), with: .color(Self.armC))

        // Dumbbell: [weight] ─ bar ─ [weight], centred on the fist
        let fistCenter = shoulderX + 0.6
        let sizeMul = CGFloat(dumbbellSize)
        let weightW: CGFloat = 1.9 * sizeMul
        let weightH: CGFloat = 2.6 * sizeMul
        let gap: CGFloat = 1.0 * sizeMul
        let dumbbellW = weightW * 2 + gap
        let dbX = fistCenter - dumbbellW / 2
        let dbY = fistY - weightH / 2 + 0.3
        let corner = v.s * 0.55 * sizeMul   // subtle round-off on the weights
        // Left weight (rounded)
        c.fill(Path(roundedRect: v.r(dbX, dbY, weightW, weightH), cornerRadius: corner),
               with: .color(Self.dumbbellC))
        // Connecting bar — thin, centred vertically between weights
        let barH: CGFloat = 0.8 * sizeMul
        c.fill(Path(v.r(dbX + weightW, dbY + (weightH - barH) / 2, gap, barH)),
               with: .color(Self.dumbbellC))
        // Right weight (rounded)
        c.fill(Path(roundedRect: v.r(dbX + weightW + gap, dbY, weightW, weightH), cornerRadius: corner),
               with: .color(Self.dumbbellC))
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // ALERT — 3.5s cycle: startle → decaying jumps → rest
    // Matches clawd-notification.svg keyframes
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    private var alertScene: some View {
        ZStack {
            Circle()
                .fill(Self.alertC.opacity(alive ? 0.12 : 0))
                .frame(width: size * 0.8)
                .blur(radius: size * 0.05)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: alive)

            TimelineView(.periodic(from: .now, by: 0.03)) { ctx in
                alertCanvas(t: ctx.date.timeIntervalSinceReferenceDate * speed)
            }
        }
    }

    // Interpolate between keyframes: [(pct, value)]
    private func lerp(_ keyframes: [(CGFloat, CGFloat)], at pct: CGFloat) -> CGFloat {
        guard let first = keyframes.first else { return 0 }
        if pct <= first.0 { return first.1 }
        for i in 1..<keyframes.count {
            if pct <= keyframes[i].0 {
                let t = (pct - keyframes[i-1].0) / (keyframes[i].0 - keyframes[i-1].0)
                return keyframes[i-1].1 + (keyframes[i].1 - keyframes[i-1].1) * t
            }
        }
        return keyframes.last?.1 ?? 0
    }

    private func alertCanvas(t: Double) -> some View {
        let cycle = t.truncatingRemainder(dividingBy: 3.5)
        let pct = cycle / 3.5

        // Body jump — smooth interpolation from SVG keyframes
        let jumpY = lerp([
            (0, 0), (0.03, 0), (0.10, -1), (0.15, 1.5),
            (0.175, -10), (0.20, -10), (0.25, 1.5),
            (0.275, -8), (0.30, -8), (0.35, 1.2),
            (0.375, -5), (0.40, -5), (0.45, 1.0),
            (0.475, -3), (0.50, -3), (0.55, 0.5),
            (0.62, 0), (1.0, 0),
        ], at: pct)

        // Squash/stretch on landing (exaggerated for visibility)
        let scaleX: CGFloat = jumpY > 0.5 ? 1.0 + jumpY * 0.05 : 1.0  // squash wider
        let scaleY: CGFloat = jumpY > 0.5 ? 1.0 - jumpY * 0.04 : 1.0  // squash shorter

        // Arm waving — smooth interpolation
        let armL = lerp([
            (0, 0), (0.03, 0), (0.10, 25),
            (0.15, 30), (0.20, 155), (0.25, 115),
            (0.30, 140), (0.35, 100), (0.40, 115),
            (0.45, 80), (0.50, 80), (0.55, 40),
            (0.62, 0), (1.0, 0),
        ], at: pct)
        let armR = -lerp([
            (0, 0), (0.03, 0), (0.10, 30),
            (0.15, 30), (0.20, 155), (0.25, 115),
            (0.30, 140), (0.35, 100), (0.40, 115),
            (0.45, 80), (0.50, 80), (0.55, 40),
            (0.62, 0), (1.0, 0),
        ], at: pct)

        // Eye startle: widen + shift gaze on initial startle
        let eyeScale: CGFloat = (pct > 0.03 && pct < 0.15) ? 1.3 : 1.0
        let eyeDY: CGFloat = (pct > 0.03 && pct < 0.15) ? -0.5 : 0

        // ! mark
        let bangOpacity = lerp([
            (0, 0), (0.03, 1), (0.10, 1), (0.55, 1), (0.62, 0), (1.0, 0),
        ], at: pct)
        let bangScale = lerp([
            (0, 0.3), (0.03, 1.3), (0.10, 1.0), (0.55, 1.0), (0.62, 0.6), (1.0, 0.6),
        ], at: pct)

        return Canvas { c, sz in
            // Taller viewport to fit ! mark above head
            let v = V(sz, svgW: 15, svgH: 12, svgY0: 4)

            // Shadow — reacts to jump height
            let shadowW: CGFloat = 9 * (1.0 - abs(min(0, jumpY)) * 0.04)
            let shadowOp = max(0.08, 0.5 - abs(min(0, jumpY)) * 0.04)
            c.fill(Path(v.r(3 + (9 - shadowW) / 2, 15, shadowW, 1)),
                   with: .color(.black.opacity(shadowOp)))

            // Legs
            for x: CGFloat in [3, 5, 9, 11] {
                c.fill(Path(v.r(x, 11, 1, 4)), with: .color(Self.bodyC))
            }

            // Torso with squash/stretch
            let torsoW = 11 * scaleX
            let torsoH = 7 * scaleY
            let torsoX = 2 - (torsoW - 11) / 2
            let torsoY = 6 + (7 - torsoH)  // stretch from bottom
            c.fill(Path(v.r(torsoX, torsoY, torsoW, torsoH, dy: jumpY)),
                   with: .color(Self.bodyC))

            // Eyes (startled = wider)
            let eyeH = 2 * eyeScale
            let eyeYPos = 8 + (2 - eyeH) / 2 + eyeDY
            c.fill(Path(v.r(4, eyeYPos, 1, eyeH, dy: jumpY)), with: .color(Self.eyeC))
            c.fill(Path(v.r(10, eyeYPos, 1, eyeH, dy: jumpY)), with: .color(Self.eyeC))

            // Arms — correct pivot at body connection
            c.fill(armPath(v, x: 0, y: 9, w: 2, h: 2, pivotX: 2, pivotY: 10,
                           angle: armL, dy: jumpY), with: .color(Self.bodyC))
            c.fill(armPath(v, x: 13, y: 9, w: 2, h: 2, pivotX: 13, pivotY: 10,
                           angle: armR, dy: jumpY), with: .color(Self.bodyC))

            // ! mark — positioned above head, dampened movement (doesn't fly off screen)
            if bangOpacity > 0.01 {
                let bw: CGFloat = 2 * bangScale
                let bx: CGFloat = 13
                let by: CGFloat = 4.5 + jumpY * 0.15 // dampened: only 15% of jump
                c.fill(Path(v.r(bx, by, bw, 3.5 * bangScale, dy: 0)),
                       with: .color(Self.alertC.opacity(bangOpacity)))
                c.fill(Path(v.r(bx, by + 4.0 * bangScale, bw, 1.5 * bangScale, dy: 0)),
                       with: .color(Self.alertC.opacity(bangOpacity)))
            }
        }
    }
}
