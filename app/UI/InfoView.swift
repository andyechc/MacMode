import SwiftUI

/// Standalone Info panel (own window). Shows what the current mode
/// activates, with per-feature applied/pending status.
struct InfoView: View {
    var manager: ModeManager

    private var mode: AppMode { manager.currentMode }
    private var applied: Bool { manager.confirmedMode == mode }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Circle()
                    .fill(applied ? Color.green : Color.orange)
                    .frame(width: 12, height: 12)
                VStack(alignment: .leading, spacing: 1) {
                    Text(mode.name).font(.headline)
                    Text(applied ? "Applied on this system" : "Saved — not applied yet")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
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

            Spacer(minLength: 0)
        }
        .tint(mode.color.color)
        .padding(16)
        .frame(width: 320)
    }
}
