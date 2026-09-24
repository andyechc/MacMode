import SwiftUI

@main
struct MacModeApp: App {
    @State private var manager = ModeManager(
        features: FeatureManager(features: [
            FunctionKeyFeature(controller: IOKitFunctionKeyStore())
        ]),
        store: UserDefaultsModeStore()
    )
    @StateObject private var opener = WindowOpener()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(manager: manager, opener: opener)
        } label: {
            Label(manager.currentMode.name, systemImage: "slider.horizontal.3")
        }
        .menuBarExtraStyle(.window)
    }
}
