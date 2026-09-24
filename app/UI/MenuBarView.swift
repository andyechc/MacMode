import SwiftUI

/// Menu bar popover (window style). Accent color follows the current mode.
/// A select always shows the current mode; switching applies it through
/// `ModeManager`. "Active now" appears only after system confirmation.
struct MenuBarView: View {
    var manager: ModeManager

    @State private var infoHover = false
    @State private var infoPinned = false
    @State private var showSettings = false

    private var mode: AppMode { manager.currentMode }
    private var infoVisible: Bool { infoHover || infoPinned }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Divider()
            modeSelect
            statusRow
            if let error = manager.lastError {
                errorRow(error)
            }
            Divider()
            infoRow
            if infoVisible {
                infoDetail
            }
            settingsRow
            Divider()
            footer
        }
        .tint(mode.color.color)
        .padding(14)
        .frame(width: 280)
        .sheet(isPresented: $showSettings) {
            SettingsView(manager: manager)
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: mode.functionKeys == .function ? "keyboard" : "gamecontroller")
                .font(.title2)
                .foregroundStyle(mode.color.color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 1) {
                Text("MacMode").font(.headline)
                Text(mode.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospaced()
            }
            Spacer()
            Circle()
                .fill(manager.isApplying ? Color.orange : mode.color.color)
                .frame(width: 10, height: 10)
        }
    }

    private var modeSelect: some View {
        Picker("Mode", selection: modeIDBinding) {
            ForEach(manager.modes) { item in
                Text(item.name).tag(item.id)
            }
        }
        .pickerStyle(.menu)
        .disabled(manager.isApplying)
    }

    private var statusRow: some View {
        HStack(spacing: 6) {
            if manager.isApplying {
                ProgressView().scaleEffect(0.7).frame(width: 16, height: 16)
                Text("Applying…").font(.caption).foregroundStyle(.secondary)
            } else if manager.confirmedMode == manager.currentMode {
                Text("\(mode.name) active now")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Text("Saved: \(mode.name) — not confirmed on this system yet")
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

    private var infoRow: some View {
        Button {
            infoPinned.toggle()
        } label: {
            HStack {
                Label("Information", systemImage: "info.circle")
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .onHover { infoHover = $0 }
    }

    private var infoDetail: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Active in \(mode.name)")
                .font(.caption).fontWeight(.semibold)
            ForEach(manager.systemFeatures, id: \.identifier) { feature in
                HStack(alignment: .top, spacing: 6) {
                    Circle()
                        .fill(manager.confirmedMode == mode ? Color.green : Color.orange)
                        .frame(width: 7, height: 7)
                        .padding(.top, 4)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(feature.identifier)
                            .font(.caption).fontWeight(.medium)
                        Text(feature.summary(for: mode))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            if manager.confirmedMode != mode {
                Text("Pending — switch to this mode to apply it.")
                    .font(.caption).foregroundStyle(.orange)
            }
        }
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }

    private var settingsRow: some View {
        Button {
            showSettings = true
        } label: {
            Label("Settings…", systemImage: "gearshape")
        }
        .buttonStyle(.plain)
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

    private var modeIDBinding: Binding<UUID> {
        Binding(
            get: { manager.currentMode.id },
            set: { id in
                if let target = manager.modes.first(where: { $0.id == id }) {
                    Task { await manager.setMode(target) }
                }
            }
        )
    }
}
