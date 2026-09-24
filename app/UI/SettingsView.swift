import SwiftUI

/// Mode library editor (standalone window). Rename modes, recolor them, change
/// their Function Key behavior, add new ones, delete unneeded ones.
/// At least one mode always remains.
struct SettingsView: View {
    var manager: ModeManager

    @State private var newName = ""
    @State private var newColor: ModeColor = .green
    @State private var newFunctionKeys: FunctionKeyMode = .media

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Modes").font(.headline)
            Text("Each mode sets its own Function Key behavior when applied.")
                .font(.caption).foregroundStyle(.secondary)

            ForEach(manager.modes) { mode in
                ModeRowView(modeID: mode.id, manager: manager)
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Add mode").font(.subheadline).fontWeight(.medium)
                TextField("Name", text: $newName)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Picker("Color", selection: $newColor) {
                        ForEach(ModeColor.allCases, id: \.self) { color in
                            Text(color.label).tag(color)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 130)
                    Picker("Keys", selection: $newFunctionKeys) {
                        Text("Function").tag(FunctionKeyMode.function)
                        Text("Media").tag(FunctionKeyMode.media)
                    }
                    .pickerStyle(.segmented)
                    Spacer()
                    Button("Add") {
                        manager.addMode(
                            name: newName.trimmingCharacters(in: .whitespaces),
                            color: newColor,
                            functionKeys: newFunctionKeys
                        )
                        newName = ""
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            Spacer()
            HStack {
                Spacer()
                Button("Done") { NSApp.keyWindow?.close() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(18)
        .frame(minWidth: 420, minHeight: 380)
    }
}

private struct ModeRowView: View {
    var modeID: UUID
    var manager: ModeManager

    private var mode: AppMode? {
        manager.modes.first(where: { $0.id == modeID })
    }

    var body: some View {
        if let mode {
            HStack(spacing: 8) {
                Circle()
                    .fill(mode.color.color)
                    .frame(width: 10, height: 10)
                TextField("Name", text: Binding(
                    get: { mode.name },
                    set: { manager.updateMode(AppMode(id: mode.id, name: $0, color: mode.color, functionKeys: mode.functionKeys)) }
                ))
                .textFieldStyle(.roundedBorder)
                Picker("Color", selection: Binding(
                    get: { mode.color },
                    set: { manager.updateMode(AppMode(id: mode.id, name: mode.name, color: $0, functionKeys: mode.functionKeys)) }
                )) {
                    ForEach(ModeColor.allCases, id: \.self) { color in
                        Text(color.label).tag(color)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 96)
                Picker("Keys", selection: Binding(
                    get: { mode.functionKeys },
                    set: { manager.updateMode(AppMode(id: mode.id, name: mode.name, color: mode.color, functionKeys: $0)) }
                )) {
                    Text("Fn").tag(FunctionKeyMode.function)
                    Text("Media").tag(FunctionKeyMode.media)
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
                if manager.currentMode.id == mode.id {
                    Text("current").font(.caption).foregroundStyle(.secondary)
                }
                Button(role: .destructive) {
                    manager.deleteMode(id: mode.id)
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(manager.modes.count <= 1)
                .help("Delete mode")
            }
        }
    }
}
