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
                LibraryPane()
            case .performance:
                PerformancePane(isAdvanced: isAdvanced)
            case .wallpapers:
                WallpapersPane()
            case .diagnostics:
                DiagnosticsPane()
            case .about:
                AboutPane()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
