import SwiftUI

@main
struct WaraqApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            // Phase 2 implements the real Settings window per
            // docs/design/settings-shell.md.
            EmptyView()
        }
    }
}
