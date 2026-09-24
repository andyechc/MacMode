import Foundation

/// Persistence behind a protocol so tests never touch real user defaults.
/// Intentionally not Sendable: owners are MainActor-confined.
public protocol ModeStore {
    func loadMode() -> MacMode?
    func saveMode(_ mode: MacMode)
}

public struct UserDefaultsModeStore: ModeStore {
    private let defaults: UserDefaults
    private let key = "currentMode"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func loadMode() -> MacMode? {
        guard let raw = defaults.string(forKey: key) else { return nil }
        return MacMode(rawValue: raw)
    }

    public func saveMode(_ mode: MacMode) {
        defaults.set(mode.rawValue, forKey: key)
    }
}
