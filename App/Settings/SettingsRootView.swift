import SwiftUI

/// Root view for the Settings window. NavigationSplitView with the
/// sidebar on the left and the selected pane on the right.
struct SettingsRootView: View {
    @AppStorage("selectedPane") private var selectedPane: PaneID = .general
    @AppStorage("isAdvancedMode") private var isAdvanced: Bool = false

    var body: some View {
        NavigationSplitView {
            SettingsSidebar(
                selectedPane: $selectedPane,
                isAdvanced: $isAdvanced
            )
            .navigationSplitViewColumnWidth(min: 190, ideal: 190, max: 220)
        } detail: {
            SettingsDetail(
                pane: selectedPane,
                isAdvanced: isAdvanced
            )
        }
        .navigationTitle("Settings")
    }
}

enum PaneID: String, CaseIterable, Identifiable {
    case general
    case displays
    case library
    case performance
    case wallpapers
    case diagnostics
    case about

    var id: String {
        rawValue
    }

    var label: String {
        switch self {
        case .general: "General"
        case .displays: "Displays"
        case .library: "Library"
        case .performance: "Performance"
        case .wallpapers: "Wallpapers"
        case .diagnostics: "Diagnostics"
        case .about: "About"
        }
    }

    var icon: String {
        switch self {
        case .general: "gearshape"
        case .displays: "display"
        case .library: "photo.on.rectangle"
        case .performance: "speedometer"
        case .wallpapers: "square.stack.3d.up"
        case .diagnostics: "stethoscope"
        case .about: "info.circle"
        }
    }

    /// Returns true if this pane should be visible in the sidebar
    /// for the given Advanced mode state.
    func isVisible(advanced: Bool) -> Bool {
        if self == .diagnostics { return advanced }
        return true
    }
}
