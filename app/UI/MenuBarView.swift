import SwiftUI

/// Scaffold menu. Shows real manager state only; mode switching and system
/// integration land with Phase 3 (nothing here claims to change the system).
struct MenuBarView: View {
    var manager: ModeManager

    var body: some View {
        Text("MacMode — \(manager.currentMode.displayName)")
            .font(.headline)
        Divider()
        Button("Quit MacMode") {
            NSApplication.shared.terminate(nil)
        }
    }
}
