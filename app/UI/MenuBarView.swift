import SwiftUI

/// Menu bar popover. The segmented control commits the mode through
/// `ModeManager`; a mode is shown as "Active now" only after the system
/// confirms it (`confirmedMode`). Errors are shown in plain language.
struct MenuBarView: View {
    var manager: ModeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MacMode").font(.headline)
            Picker("Mode", selection: modeBinding) {
                Text("DEV").tag(MacMode.dev)
                Text("GAMING").tag(MacMode.gaming)
            }
            .pickerStyle(.segmented)
            .disabled(manager.isApplying)
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

    private var modeBinding: Binding<MacMode> {
        Binding(
            get: { manager.currentMode },
            set: { newMode in Task { await manager.setMode(newMode) } }
        )
    }
}
