//  Waraq - A native macOS animated wallpaper app.
//  Copyright (C) 2026 Omar A. Othman
//
//  This program is free software: you can redistribute it
//  and/or modify it under the terms of the GNU General
//  Public License as published by the Free Software
//  Foundation, either version 3 of the License, or (at
//  your option) any later version.
//
//  This program is distributed in the hope that it will
//  be useful, but WITHOUT ANY WARRANTY; without even the
//  implied warranty of MERCHANTABILITY or FITNESS FOR A
//  PARTICULAR PURPOSE. See the GNU General Public License
//  for more details.
//
//  You should have received a copy of the GNU General
//  Public License along with this program. If not, see
//  <https://www.gnu.org/licenses/>.
//

import SwiftUI

struct PerformancePane: View {
    let isAdvanced: Bool

    @EnvironmentObject var displayManager: DisplayManager

    /// Pause settings (already set up by General pane, we read same keys)
    @AppStorage("pauseOnFullscreen")
    private var pauseOnFullscreen: Bool = true
    @AppStorage("pauseWhenScreenLocked")
    private var pauseWhenScreenLocked: Bool = true
    @AppStorage("pauseOnBattery")
    private var pauseOnBattery: Bool = true
    @AppStorage("pauseInLowPowerMode")
    private var pauseInLowPowerMode: Bool = true
    @AppStorage("pauseOnThermal")
    private var pauseOnThermal: Bool = true
    @AppStorage("batteryThreshold")
    private var batteryThreshold: Int = 35
    @AppStorage("thermalLevel")
    private var thermalLevel: String = "fair"
    @AppStorage("renderQuality")
    private var renderQuality: String = "auto"
    @AppStorage("decodeMode")
    private var decodeMode: String = "hardware"
    @AppStorage("capFrameRate")
    private var capFrameRate: Bool = true
    @AppStorage("dropFramesOnLoad")
    private var dropFramesOnLoad: Bool = true
    @AppStorage("maxMemoryMB")
    private var maxMemoryMB: Double = 250
    @AppStorage("yieldToGPUApps")
    private var yieldToGPUApps: Bool = false

    @State private var showingExemptions = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                titleRow
                liveStatusBanner
                if isAdvanced {
                    advancedPauseTriggers
                    advancedRendering
                    advancedResourceLimits
                } else {
                    basicPauseBehavior
                    basicQuality
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
        .sheet(isPresented: $showingExemptions) {
            ExemptionListSheet()
        }
    }

    private var titleRow: some View {
        HStack {
            Text("Performance")
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
        .padding(.bottom, 16)
    }

    private var liveStatusBanner: some View {
        let cpu = displayManager.resourceMonitor.cpuPercent
        let mem = displayManager.resourceMonitor.memoryMB
        let cpuColor: Color = cpu > 10 ? .orange : .green
        let memColor: Color = mem > 200 ? .orange : .green
        let displays = displayManager.displays.count

        return HStack(spacing: 12) {
            Image(systemName: "leaf")
                .font(.system(size: 18))
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 0) {
                    Text("Waraq is using ")
                        .font(.system(size: 12))
                    Text(String(format: "%.1f%%", cpu))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(cpuColor)
                    Text(" CPU and ")
                        .font(.system(size: 12))
                    Text(String(format: "%.0f MB", mem))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(memColor)
                    Text(" right now")
                        .font(.system(size: 12))
                }
                Text("Playing on \(displays) display\(displays == 1 ? "" : "s") · Thermal: \(displayManager.governor.thermalStateLabel)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.green.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.green.opacity(0.20), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // Basic mode

    private var basicPauseBehavior: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("PAUSE BEHAVIOR")
            Card {
                SettingRow(title: "Pause when an app goes fullscreen") {
                    Toggle("", isOn: $pauseOnFullscreen)
                        .toggleStyle(.switch).labelsHidden()
                }
                if displayManager.governor.isPortable {
                    Divider()
                    SettingRow(title: "Pause on battery") {
                        Toggle("", isOn: $pauseOnBattery)
                            .toggleStyle(.switch).labelsHidden()
                    }
                }
                Divider()
                SettingRow(title: "Pause in Low Power Mode") {
                    Toggle("", isOn: $pauseInLowPowerMode)
                        .toggleStyle(.switch).labelsHidden()
                }
            }
        }
    }

    private var basicQuality: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("QUALITY")
            Card {
                SettingRow(
                    title: "Render quality",
                    sublabel: "Auto adapts to your hardware"
                ) {
                    Picker("", selection: $renderQuality) {
                        Text("Auto").tag("auto")
                        Text("High").tag("high")
                        Text("Medium").tag("medium")
                        Text("Low").tag("low")
                    }
                    .pickerStyle(.menu).labelsHidden().frame(width: 110)
                }
            }
        }
    }

    // Advanced mode

    private var advancedPauseTriggers: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("PAUSE TRIGGERS")
            Card {
                SettingRow(
                    title: "Pause when an app goes fullscreen",
                    sublabel: nil
                ) {
                    Toggle("", isOn: $pauseOnFullscreen)
                        .toggleStyle(.switch).labelsHidden()
                }
                if pauseOnFullscreen {
                    Divider()
                    SettingRow(
                        title: "Exempt apps",
                        sublabel: "Apps that won't trigger pause"
                    ) {
                        Button("Manage...") {
                            showingExemptions = true
                        }
                        .controlSize(.small)
                    }
                }

                if displayManager.governor.isPortable {
                    Divider()
                    SettingRow(title: "Pause on battery") {
                        Toggle("", isOn: $pauseOnBattery)
                            .toggleStyle(.switch).labelsHidden()
                    }
                    if pauseOnBattery {
                        Divider()
                        batteryThresholdRow
                    }
                }

                Divider()
                SettingRow(title: "Pause in Low Power Mode") {
                    Toggle("", isOn: $pauseInLowPowerMode)
                        .toggleStyle(.switch).labelsHidden()
                }

                Divider()
                SettingRow(title: "Pause on thermal pressure") {
                    Toggle("", isOn: $pauseOnThermal)
                        .toggleStyle(.switch).labelsHidden()
                }
                if pauseOnThermal {
                    Divider()
                    SettingRow(
                        title: "Pause at",
                        sublabel: "Severity level"
                    ) {
                        Picker("", selection: $thermalLevel) {
                            Text("Nominal").tag("nominal")
                            Text("Fair").tag("fair")
                            Text("Serious").tag("serious")
                            Text("Critical").tag("critical")
                        }
                        .pickerStyle(.menu).labelsHidden().frame(width: 110)
                    }
                }
            }
        }
    }

    private var batteryThresholdRow: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Pause below")
                    .font(.system(size: 13))
                Text("Battery charge threshold")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            HStack(spacing: 6) {
                Slider(
                    value: Binding(
                        get: { Double(batteryThreshold) },
                        set: { batteryThreshold = Int($0) }
                    ),
                    in: 10...100, step: 5
                )
                .frame(width: 130)
                Text("\(batteryThreshold)%")
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 36, alignment: .trailing)
            }
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 14)
    }

    private var advancedRendering: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("RENDERING")
            Card {
                SettingRow(
                    title: "Render quality",
                    sublabel: nil
                ) {
                    Picker("", selection: $renderQuality) {
                        Text("Auto").tag("auto")
                        Text("High").tag("high")
                        Text("Medium").tag("medium")
                        Text("Low").tag("low")
                    }
                    .pickerStyle(.menu).labelsHidden().frame(width: 110)
                }
                Divider()
                SettingRow(
                    title: "Decode mode",
                    sublabel: "Software fallback impacts battery"
                ) {
                    Picker("", selection: $decodeMode) {
                        Text("Hardware only").tag("hardware")
                        Text("Auto").tag("auto")
                        Text("Software").tag("software")
                    }
                    .pickerStyle(.menu).labelsHidden().frame(width: 140)
                }
                Divider()
                SettingRow(title: "Cap frame rate per display") {
                    Toggle("", isOn: $capFrameRate)
                        .toggleStyle(.switch).labelsHidden()
                }
                Divider()
                SettingRow(
                    title: "Drop frames on heavy load",
                    sublabel: "Sacrifices smoothness for responsiveness"
                ) {
                    Toggle("", isOn: $dropFramesOnLoad)
                        .toggleStyle(.switch).labelsHidden()
                }
            }
        }
    }

    private var advancedResourceLimits: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("RESOURCE LIMITS")
            Card {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Max memory per wallpaper")
                            .font(.system(size: 13))
                    }
                    Spacer(minLength: 12)
                    HStack(spacing: 6) {
                        Slider(
                            value: $maxMemoryMB,
                            in: 50...500, step: 25
                        )
                        .frame(width: 130)
                        Text("\(Int(maxMemoryMB)) MB")
                            .font(.system(size: 12, weight: .medium))
                            .frame(width: 70, alignment: .trailing)
                    }
                }
                .padding(.vertical, 11)
                .padding(.horizontal, 14)

                // "Yield to GPU-heavy apps" toggle removed in Phase 9.9
                // pending the detection implementation — a disabled
                // control with "arrives in a future phase" read as
                // half-finished. The $yieldToGPUApps UserDefaults key
                // stays so a future re-enable doesn't reset user state.
            }
        }
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
}
