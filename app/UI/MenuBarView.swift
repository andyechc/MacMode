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

            HStack(spacing: 10) {
                sideLabel("DEV", active: manager.currentMode == .dev)
                    .frame(width: 52, alignment: .trailing)
                ModeSwitch(
                    isOn: manager.currentMode == .gaming,
                    disabled: manager.isApplying
                ) {
                    Task {
                        await manager.setMode(manager.currentMode == .gaming ? .dev : .gaming)
                    }
                }
                sideLabel("GAMING", active: manager.currentMode == .gaming)
                    .frame(width: 52, alignment: .leading)
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
}

/// Switch equivalente a un Toggle nativo, dibujado con primitivas
/// (el `Toggle(.switch)` no se renderiza en este popover).
/// Un solo control: apagado = DEV, encendido = GAMING.
struct ModeSwitch: View {
    var isOn: Bool
    var disabled: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? Color.accentColor : Color.secondary.opacity(0.35))
                    .frame(width: 46, height: 26)
                Circle()
                    .fill(.white)
                    .frame(width: 20, height: 20)
                    .padding(3)
                    .shadow(radius: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .accessibilityLabel(isOn ? "GAMING" : "DEV")
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(isOn ? "on" : "off")
    }
}
