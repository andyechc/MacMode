import Foundation
import SwiftUI

/// Accent per mode. Stored as a key (Codable-safe); mapped to `Color`.
public enum ModeColor: String, Codable, Sendable, CaseIterable {
    case blue, red, green, orange, purple, teal

    public var color: Color {
        switch self {
        case .blue: return .blue
        case .red: return .red
        case .green: return .green
        case .orange: return .orange
        case .purple: return .purple
        case .teal: return .teal
        }
    }

    public var label: String { rawValue.capitalized }
}

/// A system profile. Modes are data (built-in + user-created), not a fixed
/// enum: the library lives in `UserDefaults` and the UI renders from it.
public struct AppMode: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var color: ModeColor
    public var functionKeys: FunctionKeyMode

    public init(id: UUID = UUID(), name: String, color: ModeColor, functionKeys: FunctionKeyMode) {
        self.id = id
        self.name = name
        self.color = color
        self.functionKeys = functionKeys
    }

    // Stable identities so migrations and stored selections survive.
    public static let dev = AppMode(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        name: "DEV", color: .blue, functionKeys: .function
    )
    public static let gaming = AppMode(
        id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
        name: "GAMING", color: .red, functionKeys: .media
    )
    public static let presets: [AppMode] = [.dev, .gaming]
}
