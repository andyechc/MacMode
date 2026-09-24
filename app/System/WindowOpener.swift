import AppKit
import SwiftUI

/// Opens standalone windows. SwiftUI's `openWindow` does not reliably open
/// windows from an `LSUIElement` menu-bar agent, so windows are managed
/// explicitly with AppKit (content stays 100% SwiftUI).
@MainActor
final class WindowOpener: ObservableObject {
    private var settingsWindow: NSWindow?

    func openSettings(manager: ModeManager) {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let controller = NSHostingController(rootView: SettingsView(manager: manager))
        let window = NSWindow(contentViewController: controller)
        window.title = "Ajustes de MacMode"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()
        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        AppLog.app.info("settings window opened")
    }
}
