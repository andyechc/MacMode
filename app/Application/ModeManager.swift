import Foundation

/// Single source of truth for the active mode.
/// Same-mode requests are idempotent no-ops. Failed transitions keep the
/// previous mode and surface `lastError`; nothing is persisted on failure.
@Observable
@MainActor
public final class ModeManager {
    public private(set) var currentMode: MacMode
    public private(set) var lastError: MacModeError?
    public private(set) var isApplying = false

    private let features: FeatureManager
    private let store: any ModeStore

    public init(features: FeatureManager, store: any ModeStore) {
        self.features = features
        self.store = store
        self.currentMode = store.loadMode() ?? .dev
    }

    public func setMode(_ mode: MacMode) async {
        guard mode != currentMode else { return }
        isApplying = true
        defer { isApplying = false }
        do {
            try await features.apply(mode: mode)
            store.saveMode(mode)
            currentMode = mode
            lastError = nil
            AppLog.modes.info("mode → \(mode.rawValue)")
        } catch let error as MacModeError {
            lastError = error
            AppLog.modes.error("mode change to \(mode.rawValue) failed: \(error.localizedDescription)")
        } catch {
            lastError = .featureFailed(feature: "unknown", underlying: String(describing: error))
            AppLog.modes.error("mode change to \(mode.rawValue) failed: \(String(describing: error))")
        }
    }

    public func clearError() {
        lastError = nil
    }
}
