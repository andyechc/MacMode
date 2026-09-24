import Foundation

/// A single system capability that can be applied per mode.
/// Implementations live behind this interface; views and managers never
/// touch low-level macOS APIs directly.
public protocol SystemFeature: Sendable {
    var identifier: String { get }
    func apply(for mode: AppMode) async throws
    /// One-line, user-facing description of what this feature does in a
    /// mode (shown in the Info section). No technical details.
    func summary(for mode: AppMode) -> String
}

public extension SystemFeature {
    func summary(for mode: AppMode) -> String { "—" }
}

/// User-facing errors. Technical details go to OSLog, never to the UI.
public enum MacModeError: LocalizedError, Equatable {
    case featureFailed(feature: String, underlying: String)

    public var errorDescription: String? {
        switch self {
        case .featureFailed(let feature, _):
            return "MacMode couldn't change \(feature). Check the required permissions in System Settings and try again."
        }
    }
}
