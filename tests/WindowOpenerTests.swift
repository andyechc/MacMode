import XCTest
@testable import MacMode

/// Guards the regression where Settings produced no visible window:
/// opening must yield a visible, key window with the expected title,
// and reopening must reuse it instead of stacking windows.
@MainActor
final class WindowOpenerTests: XCTestCase {

    private func waitForWindow(titled title: String, timeout: TimeInterval = 5) async throws -> NSWindow {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let window = NSApp.windows.first(where: { $0.title == title }) {
                return window
            }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        throw XCTSkip("window '\(title)' never appeared")
    }

    private func closeWindows(titled title: String) {
        NSApp.windows.filter { $0.title == title }.forEach { $0.close() }
    }

    func testOpenSettingsShowsVisibleKeyWindow() async throws {
        defer { closeWindows(titled: "Ajustes de MacMode") }
        let opener = WindowOpener()
        let manager = ModeManager(features: FeatureManager(features: []), store: makeIsolatedStore())

        opener.openSettings(manager: manager)

        let window = try await waitForWindow(titled: "Ajustes de MacMode")
        XCTAssertTrue(window.isVisible)
        XCTAssertTrue(window.styleMask.contains(.titled))
    }

    func testOpenSettingsReusesSingleWindow() async throws {
        defer { closeWindows(titled: "Ajustes de MacMode") }
        let opener = WindowOpener()
        let manager = ModeManager(features: FeatureManager(features: []), store: makeIsolatedStore())

        opener.openSettings(manager: manager)
        _ = try await waitForWindow(titled: "Ajustes de MacMode")
        opener.openSettings(manager: manager)
        _ = try await waitForWindow(titled: "Ajustes de MacMode")

        let count = NSApp.windows.filter { $0.title == "Ajustes de MacMode" }.count
        XCTAssertEqual(count, 1)
    }
}
