import CoreGraphics
import Foundation

struct DisplaySettings: Codable, Equatable {
    var enabled: Bool = true
    var fitMode: FitMode = .fill
    var volume: Double = 0
    var muted: Bool = true
    var loop: Bool = true

    enum FitMode: String, Codable, CaseIterable {
        case fill // Fill Screen
        case fit // Fit to Screen
        case stretch // Stretch to Fill Screen
        case center // Natural size, centered
        case tile // Repeat in a grid

        var label: String {
            switch self {
            case .fill: "Fill Screen"
            case .fit: "Fit to Screen"
            case .stretch: "Stretch to Fill Screen"
            case .center: "Center"
            case .tile: "Tile"
            }
        }

        var description: String {
            switch self {
            case .fill: "Crop edges to fill the display"
            case .fit: "Show entire video, may letterbox"
            case .stretch: "Stretch to fill exactly, may distort"
            case .center: "Natural pixel size, centered"
            case .tile: "Repeat in a grid across the display"
            }
        }
    }

    static let `default` = DisplaySettings()
}

enum DisplaySettingsStore {
    private static let key = "displaySettings"

    static func settings(for displayID: CGDirectDisplayID) -> DisplaySettings {
        guard let map = UserDefaults.standard.dictionary(
            forKey: key
        ) as? [String: Data],
            let data = map[String(displayID)] else { return .default }
        return (try? JSONDecoder().decode(DisplaySettings.self, from: data))
            ?? .default
    }

    static func save(
        _ settings: DisplaySettings,
        for displayID: CGDirectDisplayID
    ) {
        var map = UserDefaults.standard.dictionary(
            forKey: key
        ) as? [String: Data] ?? [:]
        if let data = try? JSONEncoder().encode(settings) {
            map[String(displayID)] = data
            UserDefaults.standard.set(map, forKey: key)
        }
    }
}
