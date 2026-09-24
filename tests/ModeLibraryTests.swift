import XCTest
@testable import MacMode

@MainActor
final class ModeLibraryTests: XCTestCase {

    func testStartsWithPresets() {
        let manager = ModeManager(features: FeatureManager(features: []), store: makeIsolatedStore())
        XCTAssertEqual(manager.modes, AppMode.presets)
        XCTAssertEqual(manager.currentMode, AppMode.dev)
    }

    func testAddModePersists() {
        let store = makeIsolatedStore()
        let manager = ModeManager(features: FeatureManager(features: []), store: store)
        let added = manager.addMode(name: "PRESENT", color: .purple, functionKeys: .function)

        XCTAssertTrue(manager.modes.contains(added))
        let reloaded = ModeManager(features: FeatureManager(features: []), store: store)
        XCTAssertTrue(reloaded.modes.contains(added))
    }

    func testAddedModeIsSelectable() async {
        let feature = MockFeature()
        let manager = ModeManager(
            features: FeatureManager(features: [feature]),
            store: makeIsolatedStore()
        )
        let added = manager.addMode(name: "PRESENT", color: .purple, functionKeys: .function)

        await manager.setMode(added)

        XCTAssertEqual(manager.currentMode, added)
        XCTAssertEqual(feature.appliedModes, [added])
    }

    func testUpdateModeRenamesAndPersists() {
        let store = makeIsolatedStore()
        let manager = ModeManager(features: FeatureManager(features: []), store: store)
        var renamed = AppMode.dev
        renamed.name = "CODING"
        manager.updateMode(renamed)

        XCTAssertEqual(manager.modes.first?.name, "CODING")
        let reloaded = ModeManager(features: FeatureManager(features: []), store: store)
        XCTAssertEqual(reloaded.modes.first?.name, "CODING")
    }

    func testDeleteNonSelectedMode() {
        let manager = ModeManager(features: FeatureManager(features: []), store: makeIsolatedStore())
        manager.deleteMode(id: AppMode.gaming.id)
        XCTAssertEqual(manager.modes, [AppMode.dev])
        XCTAssertEqual(manager.currentMode, AppMode.dev)
    }

    func testDeleteSelectedFallsBackWithoutApplying() async {
        let feature = MockFeature()
        let manager = ModeManager(
            features: FeatureManager(features: [feature]),
            store: makeIsolatedStore()
        )
        await manager.setMode(AppMode.gaming)
        XCTAssertEqual(feature.appliedModes, [AppMode.gaming])

        manager.deleteMode(id: AppMode.gaming.id)

        // Falls back to DEV selected but unconfirmed (no silent apply).
        XCTAssertEqual(manager.currentMode, AppMode.dev)
        XCTAssertEqual(feature.appliedModes, [AppMode.gaming])
    }

    func testCannotDeleteLastMode() {
        let manager = ModeManager(features: FeatureManager(features: []), store: makeIsolatedStore())
        manager.deleteMode(id: AppMode.gaming.id)
        manager.deleteMode(id: AppMode.dev.id)
        XCTAssertEqual(manager.modes, [AppMode.dev])
    }
}
