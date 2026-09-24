import Foundation

/// Applies the registered features for a mode, in order.
/// Fails fast with the offending feature's identifier.
@Observable
@MainActor
public final class FeatureManager {
    private let features: [any SystemFeature]

    public init(features: [any SystemFeature] = []) {
        self.features = features
    }

    public func apply(mode: MacMode) async throws {
        for feature in features {
            do {
                try await feature.apply(for: mode)
            } catch {
                AppLog.system.error("feature \(feature.identifier) failed for \(mode.rawValue): \(String(describing: error))")
                throw MacModeError.featureFailed(feature: feature.identifier, underlying: String(describing: error))
            }
        }
    }
}
