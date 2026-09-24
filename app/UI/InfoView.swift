import SwiftUI

/// Info side panel (Surfshark-style): revealed on hover next to the
/// Information row, showing what the current mode activates.
struct InfoDetailView: View {
    var manager: ModeManager

    private var mode: AppMode { manager.currentMode }
    private var applied: Bool { manager.confirmedMode == mode }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(applied ? Color.green : Color.orange)
                    .frame(width: 10, height: 10)
                VStack(alignment: .leading, spacing: 1) {
                    Text(mode.name).font(.headline)
                    Text(applied ? "Applied on this system" : "Saved — not applied yet")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Divider()
            ForEach(manager.systemFeatures, id: \.identifier) { feature in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(applied ? mode.color.color : Color.orange)
                        .frame(width: 8, height: 8)
                        .padding(.top, 4)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.identifier)
                            .font(.subheadline).fontWeight(.medium)
                        Text(feature.summary(for: mode))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .tint(mode.color.color)
        .padding(12)
        .frame(width: 260)
    }
}
