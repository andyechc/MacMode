import SwiftUI

/// Menu bar popover. A single toggle switches modes: left = DEV,
/// right = GAMING. The switch reflects `currentMode`, so a failed
/// transition snaps it back automatically. A mode is shown as
/// "Active now" only after the system confirms it (`confirmedMode`).
struct MenuBarView: View {
    var manager: ModeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MacMode").font(.headline)

            HStack(spacing: 8) {
                sideLabel("DEV", active: manager.currentMode == .dev)
                Toggle(isOn: gamingBinding) {
                    EmptyView()
                }
                .toggleStyle(.switch)
                .disabled(manager.isApplying)
                .labelsHidden()
                sideLabel("GAMING", active: manager.currentMode == .gaming)
            }
            .frame(width: 220)

            if manager.isApplying {
                Text("Applying…").font(.caption).foregroundStyle(.secondary)
            } else if manager.confirmedMode == manager.currentMode {
                Text("\(manager.currentMode.displayName) active now")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Text("Saved preference: \(manager.currentMode.displayName) — not yet confirmed on this system")
                    .font(.caption).foregroundStyle(.secondary)
            }

            if let error = manager.lastError {
                Text(error.localizedDescription)
                    .font(.caption).foregroundStyle(.red)
                    .frame(width: 220, alignment: .leading)
            }

            Divider()
            Button("Quit MacMode") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(12)
    }

    private func sideLabel(_ text: String, active: Bool) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(active ? .bold : .regular)
            .foregroundStyle(active ? .primary : .secondary)
    }

    private var gamingBinding: Binding<Bool> {
        Binding(
            get: { manager.currentMode == .gaming },
            set: { isGaming in Task { await manager.setMode(isGaming ? .gaming : .dev) } }
        )
    }
}
