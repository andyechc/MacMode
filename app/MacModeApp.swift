import SwiftUI

@main
struct MacModeApp: App {
    @State private var manager = ModeManager(
        features: FeatureManager(features: [
            FunctionKeyFeature(controller: IOKitFunctionKeyStore())
        ]),
        store: UserDefaultsModeStore()
    )

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(manager: manager)
        } label: {
            Label(manager.currentMode.name, systemImage: "slider.horizontal.3")
        }
        .menuBarExtraStyle(.window)

        Window("Información", id: "info") {
            InfoView(manager: manager)
        }
        .windowResizability(.contentSize)

        Window("Ajustes de MacMode", id: "settings") {
            SettingsView(manager: manager)
        }
        .windowResizability(.contentSize)
    }
}
