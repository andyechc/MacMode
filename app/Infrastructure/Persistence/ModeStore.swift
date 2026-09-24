import Foundation

/// Persistence for the mode library + selection behind a protocol so tests
/// never touch real user defaults. Migrates the legacy single-mode key.
public protocol ModeStore {
    func loadLibrary() -> [AppMode]?
    func saveLibrary(_ modes: [AppMode])
    func loadSelectedID() -> UUID?
    func saveSelectedID(_ id: UUID)
}

public struct UserDefaultsModeStore: ModeStore {
    private let defaults: UserDefaults
    private let libraryKey = "modes.library.v1"
    private let selectionKey = "modes.selectedID.v1"
    private let legacyKey = "currentMode"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func loadLibrary() -> [AppMode]? {
        guard let data = defaults.data(forKey: libraryKey) else { return nil }
        let modes = try? JSONDecoder().decode([AppMode].self, from: data)
        return (modes?.isEmpty == false) ? modes : nil
    }

    public func saveLibrary(_ modes: [AppMode]) {
        if let data = try? JSONEncoder().encode(modes) {
            defaults.set(data, forKey: libraryKey)
        }
    }

    public func loadSelectedID() -> UUID? {
        if let raw = defaults.string(forKey: selectionKey) {
            return UUID(uuidString: raw)
        }
        // Migrate the pre-library single preference ("dev"/"gaming").
        if let legacy = defaults.string(forKey: legacyKey) {
            return legacy == "gaming" ? AppMode.gaming.id : AppMode.dev.id
        }
        return nil
    }

    public func saveSelectedID(_ id: UUID) {
        defaults.set(id.uuidString, forKey: selectionKey)
    }
}
