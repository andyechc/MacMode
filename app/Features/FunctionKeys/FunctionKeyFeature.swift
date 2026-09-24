import Foundation

/// Maps `MacMode` onto driver state. DEV keeps standard function keys
/// (IDEs/debuggers); GAMING keeps media keys (no Fn required).
public struct FunctionKeyFeature: SystemFeature {
    public let identifier = "function-keys"
    private let controller: any FunctionKeyController

    public init(controller: any FunctionKeyController) {
        self.controller = controller
    }

    public func apply(for mode: MacMode) async throws {
        try await controller.applyMode(mode == .dev ? .function : .media)
    }
}
