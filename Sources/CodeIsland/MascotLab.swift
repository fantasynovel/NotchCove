import AppKit
import SwiftUI
import CodeIslandCore

// MARK: - Mascot Lab — live preview + parameter tuning for the Clawd mascot

@MainActor
final class MascotLabWindowController {
    static let shared = MascotLabWindowController()
    private var window: NSWindow?
    private var closeObserver: NSObjectProtocol?

    func show() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let view = MascotLabView()
        let hosting = NSHostingView(rootView: view)
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 440),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        w.title = "Mascot Lab"
        w.contentView = hosting
        w.center()
        w.isReleasedWhenClosed = false
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        closeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification, object: w, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.window = nil
                if let obs = self?.closeObserver {
                    NotificationCenter.default.removeObserver(obs)
                    self?.closeObserver = nil
                }
            }
        }
        window = w
    }
}

private struct MascotLabView: View {
    @AppStorage(SettingsKey.clawdCurlCycleMs) private var cycleMs = SettingsDefaults.clawdCurlCycleMs
    @AppStorage(SettingsKey.clawdCurlArmRaise) private var armRaise = SettingsDefaults.clawdCurlArmRaise
    @AppStorage(SettingsKey.clawdCurlSway) private var sway = SettingsDefaults.clawdCurlSway
    @AppStorage(SettingsKey.clawdDumbbellSize) private var dumbbellSize = SettingsDefaults.clawdDumbbellSize

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Preview strip — three states side by side
            HStack(spacing: 28) {
                previewColumn(label: "Idle", status: .idle)
                previewColumn(label: "Processing", status: .processing)
                previewColumn(label: "Approval", status: .waitingApproval)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.75))
            )

            // Sliders
            VStack(alignment: .leading, spacing: 10) {
                slider(
                    title: "Cycle",
                    unit: "ms",
                    value: Binding(get: { Double(cycleMs) }, set: { cycleMs = Int($0) }),
                    range: 400...2500, step: 50
                )
                slider(
                    title: "Arm raise",
                    unit: "u",
                    value: $armRaise,
                    range: 2...8, step: 0.25
                )
                slider(
                    title: "Body sway",
                    unit: "",
                    value: $sway,
                    range: 0...0.5, step: 0.01
                )
                slider(
                    title: "Dumbbell size",
                    unit: "×",
                    value: $dumbbellSize,
                    range: 0.5...2.0, step: 0.05
                )
            }

            Spacer(minLength: 0)

            HStack {
                Spacer()
                Button("Reset defaults") {
                    cycleMs = SettingsDefaults.clawdCurlCycleMs
                    armRaise = SettingsDefaults.clawdCurlArmRaise
                    sway = SettingsDefaults.clawdCurlSway
                    dumbbellSize = SettingsDefaults.clawdDumbbellSize
                }
            }
        }
        .padding(18)
        .frame(minWidth: 480, minHeight: 400)
    }

    private func previewColumn(label: String, status: AgentStatus) -> some View {
        VStack(spacing: 8) {
            ClawdView(status: status, size: 96)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private func slider(title: String, unit: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                Spacer()
                Text(formatValue(value.wrappedValue, unit: unit))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: step)
        }
    }

    private func formatValue(_ v: Double, unit: String) -> String {
        if unit == "ms" { return "\(Int(v))\(unit)" }
        return String(format: "%.2f%@", v, unit.isEmpty ? "" : " \(unit)")
    }
}
