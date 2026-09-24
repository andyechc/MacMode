import Foundation

/// System profile. Discrete by design — the UI slider is only a visual
/// representation; there is no intermediate system state.
public enum MacMode: String, Codable, Sendable, CaseIterable {
    case dev
    case gaming

    public var displayName: String {
        switch self {
        case .dev: return "DEV"
        case .gaming: return "GAMING"
        }
    }
}
