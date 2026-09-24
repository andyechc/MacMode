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
        MenuBarExtra("MacMode", systemImage: "slider.horizontal.3") {
            MenuBarView(manager: manager)
        }
    }
}
