import SwiftUI

@main
struct WaraqApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsRootView()
                .environmentObject(
                    appDelegate.displayManager ?? DisplayManager.shared
                )
                .frame(minWidth: 640, minHeight: 480)
                .frame(idealWidth: 720, idealHeight: 560)
        }
        .windowResizability(.contentSize)
    }
}
