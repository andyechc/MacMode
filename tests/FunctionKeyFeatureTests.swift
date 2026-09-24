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
        try await FunctionKeyFeature(controller: controller).apply(for: AppMode.dev)
        XCTAssertEqual(controller.appliedModes, [.function])
    }

    func testGamingMapsToMediaKeys() async throws {
        let controller = MockFunctionKeyController()
        try await FunctionKeyFeature(controller: controller).apply(for: AppMode.gaming)
        XCTAssertEqual(controller.appliedModes, [.media])
    }

    func testCustomModeUsesItsOwnSetting() async throws {
        let controller = MockFunctionKeyController()
        let custom = AppMode(name: "PRESENT", color: .purple, functionKeys: .function)
        try await FunctionKeyFeature(controller: controller).apply(for: custom)
        XCTAssertEqual(controller.appliedModes, [.function])
    }

    func testControllerErrorPropagates() async {
        let controller = MockFunctionKeyController()
        controller.errorToThrow = FunctionKeyError.setFailed(code: -1)
        do {
            try await FunctionKeyFeature(controller: controller).apply(for: AppMode.dev)
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
        await manager.setMode(AppMode.gaming)
        XCTAssertEqual(manager.confirmedMode, AppMode.gaming)
    }

    func testConfirmedUnchangedOnFailure() async {
        let controller = MockFunctionKeyController()
        let manager = ModeManager(
            features: FeatureManager(features: [FunctionKeyFeature(controller: controller)]),
            store: makeIsolatedStore()
        )
        await manager.setMode(AppMode.gaming)
        XCTAssertEqual(manager.confirmedMode, AppMode.gaming)
        controller.errorToThrow = FunctionKeyError.setFailed(code: -1)
        await manager.setMode(AppMode.dev)
        XCTAssertEqual(manager.currentMode, AppMode.gaming)
        XCTAssertEqual(manager.confirmedMode, AppMode.gaming)
    }

    func testSummaryDescribesSetting() {
        let feature = FunctionKeyFeature(controller: MockFunctionKeyController())
        XCTAssertTrue(feature.summary(for: AppMode.dev).contains("Standard"))
        XCTAssertTrue(feature.summary(for: AppMode.gaming).contains("Media"))
    }
}
