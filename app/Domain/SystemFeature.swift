import Foundation

/// A single system capability that can be applied per mode.
/// Implementations live behind this interface; views and managers never
/// touch low-level macOS APIs directly.
public protocol SystemFeature: Sendable {
    var identifier: String { get }
    func apply(for mode: MacMode) async throws
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
