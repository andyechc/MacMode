import XCTest
@testable import MacMode

@MainActor
final class ModeManagerTests: XCTestCase {

    func testDevToGamingAppliesAndPersists() async {
        let feature = MockFeature()
        let manager = ModeManager(
            features: FeatureManager(features: [feature]),
            store: makeIsolatedStore()
        )
        XCTAssertEqual(manager.currentMode, .dev)

        await manager.setMode(.gaming)

        XCTAssertEqual(manager.currentMode, .gaming)
        XCTAssertEqual(feature.appliedModes, [.gaming])
        XCTAssertNil(manager.lastError)
    }

    func testGamingToDev() async {
        let feature = MockFeature()
        let store = makeIsolatedStore()
        store.saveMode(.gaming)
        let manager = ModeManager(features: FeatureManager(features: [feature]), store: store)
        XCTAssertEqual(manager.currentMode, .gaming)

        await manager.setMode(.dev)

        XCTAssertEqual(manager.currentMode, .dev)
        XCTAssertEqual(feature.appliedModes, [.dev])
    }

    func testSameModeIsNoop() async {
        let feature = MockFeature()
        let manager = ModeManager(
            features: FeatureManager(features: [feature]),
            store: makeIsolatedStore()
        )

        await manager.setMode(.dev)

        XCTAssertEqual(manager.currentMode, .dev)
        XCTAssertTrue(feature.appliedModes.isEmpty)
    }

    func testFailedTransitionKeepsModeAndSurfacesError() async {
        let feature = MockFeature(errorToThrow: BoomError())
        let store = makeIsolatedStore()
        let manager = ModeManager(features: FeatureManager(features: [feature]), store: store)

        await manager.setMode(.gaming)

        XCTAssertEqual(manager.currentMode, .dev)
        XCTAssertNotNil(manager.lastError)
        XCTAssertEqual(manager.lastError?.errorDescription?.contains("mock"), true)
        // Nothing persisted on failure: a fresh manager still reads DEV.
        let reloaded = ModeManager(features: FeatureManager(features: []), store: store)
        XCTAssertEqual(reloaded.currentMode, .dev)
    }

    func testPersistenceRestoration() async {
        let store = makeIsolatedStore()
        let first = ModeManager(features: FeatureManager(features: [MockFeature()]), store: store)
        await first.setMode(.gaming)

        let second = ModeManager(features: FeatureManager(features: []), store: store)
        XCTAssertEqual(second.currentMode, .gaming)
    }
}
