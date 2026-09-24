import Foundation

/// Maps an `AppMode` onto driver state via its `functionKeys` setting.
public struct FunctionKeyFeature: SystemFeature {
    public let identifier = "function-keys"
    private let controller: any FunctionKeyController

    public init(controller: any FunctionKeyController) {
        self.controller = controller
    }

    public func apply(for mode: AppMode) async throws {
        try await controller.applyMode(mode.functionKeys)
    }

    public func summary(for mode: AppMode) -> String {
        switch mode.functionKeys {
        case .function: return "Standard function keys (F1 acts as F1)"
        case .media: return "Media keys (F1 controls brightness, etc.)"
        }
    }
}
