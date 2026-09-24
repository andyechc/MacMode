import Foundation
@testable import MacMode

/// Test double. Records invocations; optionally throws.
final class MockFeature: SystemFeature, @unchecked Sendable {
    let identifier: String
    private(set) var appliedModes: [AppMode] = []
    var errorToThrow: Error?

    init(identifier: String = "mock", errorToThrow: Error? = nil) {
        self.identifier = identifier
        self.errorToThrow = errorToThrow
    }

    func apply(for mode: AppMode) async throws {
        appliedModes.append(mode)
        if let errorToThrow { throw errorToThrow }
    }
}

struct BoomError: Error {}

func makeIsolatedStore() -> UserDefaultsModeStore {
    let defaults = UserDefaults(suiteName: "app.macmode.tests")!
    defaults.removePersistentDomain(forName: "app.macmode.tests")
    return UserDefaultsModeStore(defaults: defaults)
}
