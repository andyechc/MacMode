import XCTest
@testable import MacMode

@MainActor
final class FeatureManagerTests: XCTestCase {

    func testEmptyFeatureListSucceeds() async throws {
        try await FeatureManager(features: []).apply(mode: AppMode.gaming)
    }

    func testAppliesAllFeaturesInOrder() async throws {
        let first = MockFeature(identifier: "first")
        let second = MockFeature(identifier: "second")

        try await FeatureManager(features: [first, second]).apply(mode: AppMode.dev)

        XCTAssertEqual(first.appliedModes, [AppMode.dev])
        XCTAssertEqual(second.appliedModes, [AppMode.dev])
    }

    func testFailureReportsFeatureIdentifier() async {
        let failing = MockFeature(identifier: "fn-keys", errorToThrow: BoomError())

        do {
            try await FeatureManager(features: [failing]).apply(mode: AppMode.gaming)
            XCTFail("expected throw")
        } catch let error as MacModeError {
            XCTAssertEqual(error, .featureFailed(feature: "fn-keys", underlying: "BoomError()"))
            XCTAssertTrue(error.localizedDescription.contains("fn-keys"))
        } catch {
            XCTFail("wrong error type: \(error)")
        }
    }
}
