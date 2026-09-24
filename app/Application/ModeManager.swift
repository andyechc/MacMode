import Foundation

/// Single source of truth for modes and selection.
/// - `modes`: the library (built-in presets + user modes), persisted.
/// - `currentMode`: desired mode (persisted selection).
/// - `confirmedMode`: mode verified against the system this launch, or nil
///   if no successful apply happened yet. The UI must not present a mode as
///   "active now" unless it is confirmed.
/// Same-mode requests are idempotent no-ops. Failed transitions keep the
/// previous mode and surface `lastError`; nothing is persisted on failure.
/// Deleting the selected mode selects a remaining one without applying
/// (it shows as unconfirmed until the user applies it).
@Observable
@MainActor
public final class ModeManager {
    public private(set) var modes: [AppMode]
    public private(set) var currentMode: AppMode
    public private(set) var confirmedMode: AppMode?
    public private(set) var lastError: MacModeError?
    public private(set) var isApplying = false

    private let features: FeatureManager
    private let store: any ModeStore

    /// Features for read-only UI (e.g. the Info section).
    public var systemFeatures: [any SystemFeature] { features.features }

    public init(features: FeatureManager, store: any ModeStore) {
        self.features = features
        self.store = store
        let library = store.loadLibrary() ?? AppMode.presets
        self.modes = library
        let selected = store.loadSelectedID().flatMap { id in library.first(where: { $0.id == id }) }
        self.currentMode = selected ?? library[0]
    }

    public func setMode(_ mode: AppMode) async {
        guard mode != currentMode else { return }
        isApplying = true
        defer { isApplying = false }
        do {
            try await features.apply(mode: mode)
            store.saveSelectedID(mode.id)
            currentMode = mode
            confirmedMode = mode
            lastError = nil
            AppLog.modes.info("mode → \(mode.name) (confirmed)")
        } catch let error as MacModeError {
            lastError = error
            AppLog.modes.error("mode change to \(mode.name) failed: \(error.localizedDescription)")
        } catch {
            lastError = .featureFailed(feature: "unknown", underlying: String(describing: error))
            AppLog.modes.error("mode change to \(mode.name) failed: \(String(describing: error))")
        }
    }

    public func clearError() {
        lastError = nil
    }

    // MARK: - Library management

    @discardableResult
    public func addMode(name: String, color: ModeColor, functionKeys: FunctionKeyMode) -> AppMode {
        let mode = AppMode(name: name, color: color, functionKeys: functionKeys)
        modes.append(mode)
        persistLibrary()
        AppLog.modes.info("mode added: \(name)")
        return mode
    }

    public func updateMode(_ mode: AppMode) {
        guard let index = modes.firstIndex(where: { $0.id == mode.id }) else { return }
        modes[index] = mode
        if currentMode.id == mode.id { currentMode = mode }
        persistLibrary()
    }

    /// Deletes a mode. At least one mode always remains. If the selected
    /// mode is deleted, selection falls back to a remaining mode without
    /// applying it (shows as unconfirmed until applied).
    public func deleteMode(id: UUID) {
        guard modes.count > 1,
              let index = modes.firstIndex(where: { $0.id == id }) else { return }
        let removed = modes.remove(at: index)
        if currentMode.id == id {
            currentMode = modes[0]
            store.saveSelectedID(currentMode.id)
        }
        persistLibrary()
        AppLog.modes.info("mode deleted: \(removed.name)")
    }

    private func persistLibrary() {
        store.saveLibrary(modes)
    }
}
