import SwiftUI

/// Menu bar popover. A single toggle button switches modes; the DEV/GAMING
/// side labels show where each mode sits, with the active side bold.
/// The button reflects `currentMode`, so a failed transition leaves it
/// unchanged. A mode is shown as "Active now" only after the system
/// confirms it (`confirmedMode`).
struct MenuBarView: View {
    var manager: ModeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MacMode").font(.headline)

            HStack(spacing: 10) {
                sideLabel("DEV", active: manager.currentMode == .dev)
                Spacer()
                sideLabel("GAMING", active: manager.currentMode == .gaming)
            }
            .frame(width: 220)

            // Single toggle control (plain text button: custom switch
            // drawing does not paint in this popover).
            Button(manager.currentMode == .gaming ? "Switch to DEV" : "Switch to GAMING") {
                Task {
                    await manager.setMode(manager.currentMode == .gaming ? .dev : .gaming)
                }
            }
            .disabled(manager.isApplying)

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
}
