import XCTest
@testable import MacMode

@MainActor
final class ModeManagerTests: XCTestCase {

    func testDevToGamingAppliesAndPersists() async {
        let feature = MockFeature()
        let store = makeIsolatedStore()
        let manager = ModeManager(
            features: FeatureManager(features: [feature]),
            store: store
        )
        XCTAssertEqual(manager.currentMode, AppMode.dev)

        await manager.setMode(AppMode.gaming)

        XCTAssertEqual(manager.currentMode, AppMode.gaming)
        XCTAssertEqual(feature.appliedModes, [AppMode.gaming])
        XCTAssertNil(manager.lastError)
        XCTAssertEqual(store.loadSelectedID(), AppMode.gaming.id)
    }

    func testGamingToDev() async {
        let feature = MockFeature()
        let store = makeIsolatedStore()
        store.saveLibrary([.dev, .gaming])
        store.saveSelectedID(AppMode.gaming.id)
        let manager = ModeManager(features: FeatureManager(features: [feature]), store: store)
        XCTAssertEqual(manager.currentMode, AppMode.gaming)

        await manager.setMode(AppMode.dev)

        XCTAssertEqual(manager.currentMode, AppMode.dev)
        XCTAssertEqual(feature.appliedModes, [AppMode.dev])
    }

    func testSameModeIsNoop() async {
        let feature = MockFeature()
        let manager = ModeManager(
            features: FeatureManager(features: [feature]),
            store: makeIsolatedStore()
        )

        await manager.setMode(AppMode.dev)

        XCTAssertEqual(manager.currentMode, AppMode.dev)
        XCTAssertTrue(feature.appliedModes.isEmpty)
    }

    func testFailedTransitionKeepsModeAndSurfacesError() async {
        let feature = MockFeature(errorToThrow: BoomError())
        let store = makeIsolatedStore()
        let manager = ModeManager(features: FeatureManager(features: [feature]), store: store)

        await manager.setMode(AppMode.gaming)

        XCTAssertEqual(manager.currentMode, AppMode.dev)
        XCTAssertNotNil(manager.lastError)
        // Nothing persisted on failure: a fresh manager still reads DEV.
        let reloaded = ModeManager(features: FeatureManager(features: []), store: store)
        XCTAssertEqual(reloaded.currentMode, AppMode.dev)
    }

    func testPersistenceRestoration() async {
        let store = makeIsolatedStore()
        let first = ModeManager(features: FeatureManager(features: [MockFeature()]), store: store)
        await first.setMode(AppMode.gaming)

        let second = ModeManager(features: FeatureManager(features: []), store: store)
        XCTAssertEqual(second.currentMode, AppMode.gaming)
    }

    func testLegacyPreferenceMigrates() {
        let defaults = UserDefaults(suiteName: "app.macmode.tests")!
        defaults.removePersistentDomain(forName: "app.macmode.tests")
        defaults.set("gaming", forKey: "currentMode")
        let manager = ModeManager(
            features: FeatureManager(features: []),
            store: UserDefaultsModeStore(defaults: defaults)
        )
        XCTAssertEqual(manager.currentMode, AppMode.gaming)
    }
}
