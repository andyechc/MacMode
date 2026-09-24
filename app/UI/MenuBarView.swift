import SwiftUI

/// Menu bar popover (window style: `.menuBarExtraStyle(.window)`).
/// A single toggle switches modes — left DEV, right GAMING — with the
/// active side emphasized. The toggle reflects `currentMode`, so a failed
/// transition leaves it unchanged. "Active now" appears only after the
/// system confirms the mode (`confirmedMode`).
struct MenuBarView: View {
    var manager: ModeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Divider()
            modeRow
            statusRow
            if let error = manager.lastError {
                errorRow(error)
            }
            Divider()
            footer
        }
        .padding(14)
        .frame(width: 280)
    }

    // MARK: - Sections

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: manager.currentMode == .gaming ? "gamecontroller" : "keyboard")
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 1) {
                Text("MacMode").font(.headline)
                Text(manager.currentMode.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospaced()
            }
            Spacer()
            Circle()
                .fill(manager.isApplying ? Color.orange : Color.green)
                .frame(width: 8, height: 8)
        }
    }

    private var modeRow: some View {
        HStack(spacing: 10) {
            sideLabel("DEV", active: manager.currentMode == .dev)
                .frame(width: 56, alignment: .trailing)
            Toggle("Mode", isOn: gamingBinding)
                .toggleStyle(.switch)
                .labelsHidden()
                .fixedSize()
                .disabled(manager.isApplying)
            sideLabel("GAMING", active: manager.currentMode == .gaming)
                .frame(width: 56, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }

    private var statusRow: some View {
        HStack(spacing: 6) {
            if manager.isApplying {
                ProgressView().scaleEffect(0.7).frame(width: 16, height: 16)
                Text("Applying…").font(.caption).foregroundStyle(.secondary)
            } else if manager.confirmedMode == manager.currentMode {
                Text("\(manager.currentMode.displayName) active now")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Text("Saved: \(manager.currentMode.displayName) — not confirmed on this system yet")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func errorRow(_ error: MacModeError) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(error.localizedDescription)
                .font(.caption).foregroundStyle(.red)
            Button("Dismiss") { manager.clearError() }
                .font(.caption)
        }
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button("Quit MacMode") {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    // MARK: - Helpers

    private func sideLabel(_ text: String, active: Bool) -> some View {
        Text(text)
            .font(.callout)
            .fontWeight(active ? .semibold : .regular)
            .foregroundStyle(active ? .primary : .secondary)
    }

    private var gamingBinding: Binding<Bool> {
        Binding(
            get: { manager.currentMode == .gaming },
            set: { isGaming in Task { await manager.setMode(isGaming ? .gaming : .dev) } }
        )
    }
}
