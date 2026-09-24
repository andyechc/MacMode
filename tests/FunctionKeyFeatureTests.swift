import XCTest
@testable import MacMode

final class MockFunctionKeyController: FunctionKeyController, @unchecked Sendable {
    private(set) var appliedModes: [FunctionKeyMode] = []
    var stubbedMode: FunctionKeyMode = .function
    var errorToThrow: Error?

    func readMode() async throws -> FunctionKeyMode {
        if let errorToThrow { throw errorToThrow }
        return stubbedMode
    }

    func applyMode(_ mode: FunctionKeyMode) async throws {
        appliedModes.append(mode)
        if let errorToThrow { throw errorToThrow }
        stubbedMode = mode
    }
}

@MainActor
final class FunctionKeyFeatureTests: XCTestCase {

    func testDevMapsToFunctionKeys() async throws {
        let controller = MockFunctionKeyController()
        try await FunctionKeyFeature(controller: controller).apply(for: .dev)
        XCTAssertEqual(controller.appliedModes, [.function])
    }

    func testGamingMapsToMediaKeys() async throws {
        let controller = MockFunctionKeyController()
        try await FunctionKeyFeature(controller: controller).apply(for: .gaming)
        XCTAssertEqual(controller.appliedModes, [.media])
    }

    func testControllerErrorPropagates() async {
        let controller = MockFunctionKeyController()
        controller.errorToThrow = FunctionKeyError.setFailed(code: -1)
        do {
            try await FunctionKeyFeature(controller: controller).apply(for: .dev)
            XCTFail("expected throw")
        } catch {
            XCTAssertTrue(error is FunctionKeyError)
        }
    }

    func testConfirmedOnlyAfterSuccessfulApply() async {
        let manager = ModeManager(
            features: FeatureManager(features: [FunctionKeyFeature(controller: MockFunctionKeyController())]),
            store: makeIsolatedStore()
        )
        XCTAssertNil(manager.confirmedMode)
        await manager.setMode(.gaming)
        XCTAssertEqual(manager.confirmedMode, .gaming)
    }

    func testConfirmedUnchangedOnFailure() async {
        let controller = MockFunctionKeyController()
        let manager = ModeManager(
            features: FeatureManager(features: [FunctionKeyFeature(controller: controller)]),
            store: makeIsolatedStore()
        )
        await manager.setMode(.gaming)
        XCTAssertEqual(manager.confirmedMode, .gaming)
        controller.errorToThrow = FunctionKeyError.setFailed(code: -1)
        await manager.setMode(.dev)
        XCTAssertEqual(manager.currentMode, .gaming)
        XCTAssertEqual(manager.confirmedMode, .gaming)
    }
}
