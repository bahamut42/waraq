import SwiftUI

struct DisplaysPane: View {
    let isAdvanced: Bool

    @EnvironmentObject var displayManager: DisplayManager
    @AppStorage("onKnownDisplay") private var onKnown: String = "restoreProfile"
    @AppStorage("onNewDisplay") private var onNew: String = "askMe"

    @State private var configuringDisplay: DisplayManager.DisplayInfo?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                titleRow

                connectedSection

                changeBehaviorSection

                if isAdvanced {
                    placeholderAdvancedSection
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
        .sheet(item: $configuringDisplay) { display in
            DisplayConfigSheet(display: display)
                .environmentObject(displayManager)
        }
    }

    private var titleRow: some View {
        HStack {
            Text("Displays")
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

    private var connectedSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("CONNECTED NOW")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(0.5)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    displayManager.showDisplayIdentification()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "1.square")
                            .font(.system(size: 10))
                        Text("Show Numbers")
                            .font(.system(size: 11))
                    }
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                Text("\(displayManager.displays.count) display\(displayManager.displays.count == 1 ? "" : "s")")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 22)
            .padding(.bottom, 8)
            .padding(.horizontal, 2)

            Card {
                ForEach(Array(displayManager.displays.enumerated()), id: \.element.id) { index, display in
                    let settings = DisplaySettingsStore.settings(for: display.id)
                    DisplayRow(
                        display: display,
                        enabled: settings.enabled,
                        isPrimary: WaraqPrimaryStore.isPrimary(
                            displayID: display.id
                        ),
                        onToggleEnabled: { newValue in
                            displayManager.setDisplayEnabled(
                                displayID: display.id,
                                enabled: newValue
                            )
                        },
                        onConfigure: {
                            configuringDisplay = display
                        },
                        onSetPrimary: { setAsPrimary(display) }
                    )
                    if index < displayManager.displays.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    /// Persist the user's chosen Waraq Primary display, then nudge the
    /// manager so the MAIN badge re-renders on the right row.
    private func setAsPrimary(_ display: DisplayManager.DisplayInfo) {
        guard let hwID = DisplayHardwareID(displayID: display.id) else {
            return
        }
        WaraqPrimaryStore.chosenHardwareID = hwID.key
        displayManager.objectWillChange.send()
    }

    private var changeBehaviorSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("WHEN DISPLAYS CHANGE")
                .font(.system(size: 11, weight: .medium))
                .tracking(0.5)
                .foregroundStyle(.secondary)
                .padding(.top, 22)
                .padding(.bottom, 8)
                .padding(.horizontal, 2)

            Card {
                SettingRow(
                    title: "When a known display connects",
                    sublabel: "Profile is recognized by hardware ID"
                ) {
                    Picker("", selection: $onKnown) {
                        Text("Restore profile").tag("restoreProfile")
                        Text("Ask me").tag("askMe")
                        Text("Use default wallpaper").tag("useDefault")
                        Text("Ignore").tag("ignore")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 170)
                }
                Divider()
                SettingRow(
                    title: "When a new display connects",
                    sublabel: "Hardware ID not seen before"
                ) {
                    Picker("", selection: $onNew) {
                        Text("Ask me").tag("askMe")
                        Text("Use default wallpaper").tag("useDefault")
                        Text("Mirror main display").tag("mirror")
                        Text("Ignore").tag("ignore")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 170)
                }
            }
        }
    }

    private var placeholderAdvancedSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("COLOR AND HDR")
                .font(.system(size: 11, weight: .medium))
                .tracking(0.5)
                .foregroundStyle(.secondary)
                .padding(.top, 22)
                .padding(.bottom, 8)
                .padding(.horizontal, 2)

            Card {
                HStack {
                    Text("Phase 4: per-display color profile matching and HDR rendering")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.vertical, 11)
                .padding(.horizontal, 14)
            }
        }
    }
}

private struct DisplayRow: View {
    let display: DisplayManager.DisplayInfo
    let enabled: Bool
    let isPrimary: Bool
    let onToggleEnabled: (Bool) -> Void
    let onConfigure: () -> Void
    let onSetPrimary: () -> Void

    var body: some View {
        rowContent
            .contextMenu {
                Button(action: onSetPrimary) {
                    if isPrimary {
                        Label("Currently Primary", systemImage: "checkmark")
                    } else {
                        Label("Set as Waraq Primary", systemImage: "star")
                    }
                }
                .disabled(isPrimary)
            }
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(
                    colors: enabled ? [
                        Color(red: 0.06, green: 0.10, blue: 0.22),
                        Color(red: 0.24, green: 0.06, blue: 0.12),
                    ] : [
                        Color.gray.opacity(0.4),
                        Color.gray.opacity(0.2),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 48, height: 30)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(
                            isPrimary
                                ? Color.accentColor.opacity(0.45)
                                : Color.primary.opacity(0.10),
                            lineWidth: isPrimary ? 1.5 : 0.5
                        )
                )
                .opacity(enabled ? 1.0 : 0.55)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(display.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(enabled ? .primary : .secondary)
                    if isPrimary {
                        Text("MAIN")
                            .font(.system(size: 9, weight: .medium))
                            .tracking(0.3)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.accentColor.opacity(0.18))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                }
                Text("\(display.width) x \(display.height)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 4) {
                Circle()
                    .fill(enabled ? Color.green : Color.gray)
                    .frame(width: 5, height: 5)
                Text(enabled ? "LIVE" : "OFF")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(enabled ? .green : .secondary)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                (enabled ? Color.green : Color.gray).opacity(0.15)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))

            Toggle("", isOn: Binding(
                get: { enabled },
                set: { onToggleEnabled($0) }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)
            .labelsHidden()

            Button("Configure") { onConfigure() }
                .controlSize(.small)
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 14)
    }
}
