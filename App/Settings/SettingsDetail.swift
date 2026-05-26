import SwiftUI

struct SettingsDetail: View {
    let pane: PaneID
    let isAdvanced: Bool

    var body: some View {
        Group {
            switch pane {
            case .general:
                GeneralPane(isAdvanced: isAdvanced)
            case .displays:
                DisplaysPane(isAdvanced: isAdvanced)
            case .library:
                PlaceholderPane(
                    title: "Library",
                    phase: "Phase 5",
                    summary: "Browse, import, and manage your animated wallpapers."
                )
            case .performance:
                PerformancePane(isAdvanced: isAdvanced)
            case .wallpapers:
                PlaceholderPane(
                    title: "Wallpapers",
                    phase: "Phase 5",
                    summary: "Defaults, rotation, scheduling, and transitions."
                )
            case .diagnostics:
                PlaceholderPane(
                    title: "Diagnostics",
                    phase: "Phase 7",
                    summary: "Logs, on-screen overlay, telemetry, reset."
                )
            case .about:
                PlaceholderPane(
                    title: "About",
                    phase: "Phase 7",
                    summary: "Version, credits, links, license."
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
