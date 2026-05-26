import SwiftUI

struct GeneralPane: View {
    let isAdvanced: Bool

    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = true
    @AppStorage("showInMenuBar") private var showInMenuBar: Bool = true
    @AppStorage("pauseWhenScreenLocked")
    private var pauseWhenScreenLocked: Bool = true
    @AppStorage("pauseOnFullscreen")
    private var pauseOnFullscreen: Bool = true
    @AppStorage("pauseInLowPowerMode")
    private var pauseInLowPowerMode: Bool = true
    @AppStorage("appAppearance") private var appAppearance: String = "system"
    @AppStorage("updateChannel") private var updateChannel: String = "stable"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                titleRow

                sectionHeader("STARTUP")
                Card {
                    SettingRow(
                        title: "Launch Waraq at login",
                        sublabel: "Starts in the background, no Dock icon"
                    ) {
                        Toggle("", isOn: $launchAtLogin)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }
                    Divider()
                    SettingRow(
                        title: "Show in menu bar",
                        sublabel: "Disable to hide the status icon"
                    ) {
                        Toggle("", isOn: $showInMenuBar)
                            .toggleStyle(.switch)
                            .labelsHidden()
                            .onChange(of: showInMenuBar) { _, newValue in
                                applyMenuBarVisibility(newValue)
                            }
                    }
                }

                sectionHeader("BEHAVIOR")
                Card {
                    SettingRow(title: "Pause when screen is locked") {
                        Toggle("", isOn: $pauseWhenScreenLocked)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }
                    Divider()
                    SettingRow(title: "Pause when an app goes fullscreen") {
                        Toggle("", isOn: $pauseOnFullscreen)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }
                    Divider()
                    SettingRow(title: "Pause in Low Power Mode") {
                        Toggle("", isOn: $pauseInLowPowerMode)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }
                }

                sectionHeader("APPEARANCE")
                Card {
                    SettingRow(
                        title: "App appearance",
                        sublabel: "Wallpaper rendering is unaffected"
                    ) {
                        Picker("", selection: $appAppearance) {
                            Text("Match system").tag("system")
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .frame(width: 130)
                        .onChange(of: appAppearance) { _, newValue in
                            applyAppearance(newValue)
                        }
                    }
                }

                sectionHeader("UPDATES")
                Card {
                    SettingRow(
                        title: "Update channel",
                        sublabel: "Choose how often you get new features"
                    ) {
                        Picker("", selection: $updateChannel) {
                            Text("Stable").tag("stable")
                            Text("Beta").tag("beta")
                            if isAdvanced {
                                Text("Nightly").tag("nightly")
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .frame(width: 110)
                    }
                    Divider()
                    SettingRow(
                        title: "Check for updates",
                        sublabel: "Waraq is up to date"
                    ) {
                        Button("Check now") {
                            // Phase 7 wires Sparkle. For now, no-op.
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
    }

    private var titleRow: some View {
        HStack {
            Text("General")
                .font(.system(size: 22, weight: .medium))
                .tracking(-0.2)
            if isAdvanced {
                Spacer()
                Text("ADVANCED")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(0.4)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(.bottom, 8)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .medium))
            .tracking(0.5)
            .foregroundStyle(.secondary)
            .padding(.top, 22)
            .padding(.bottom, 8)
            .padding(.horizontal, 2)
    }

    private func applyAppearance(_ value: String) {
        switch value {
        case "light": NSApp.appearance = NSAppearance(named: .aqua)
        case "dark": NSApp.appearance = NSAppearance(named: .darkAqua)
        default: NSApp.appearance = nil
        }
    }

    private func applyMenuBarVisibility(_ visible: Bool) {
        guard let delegate = NSApp.delegate as? AppDelegate else { return }
        delegate.applyMenuBarVisibility()
    }
}
