import SwiftUI

struct DisplaysStep: View {
    @ObservedObject var displayManager: DisplayManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepHeader(
                title: "Choose Your Displays",
                subtitle: "Pick which screens Waraq should run on."
            )

            ScrollView {
                VStack(spacing: 1) {
                    ForEach(displayManager.displays) { display in
                        DisplayToggleRow(
                            display: display,
                            displayManager: displayManager
                        )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                )
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
    }
}

private struct DisplayToggleRow: View {
    let display: DisplayManager.DisplayInfo
    @ObservedObject var displayManager: DisplayManager

    private var isEnabled: Bool {
        DisplaySettingsStore.settings(for: display.id).enabled
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "display")
                .font(.system(size: 18))
                .foregroundStyle(isEnabled ? .primary : .secondary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(display.name)
                        .font(.system(size: 13, weight: .medium))
                    if display.isMain {
                        Text("MAIN")
                            .font(.system(size: 9, weight: .medium))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.accentColor.opacity(0.18))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                }
                Text("\(display.width) × \(display.height)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { newValue in
                    displayManager.setDisplayEnabled(
                        displayID: display.id, enabled: newValue
                    )
                }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color.primary.opacity(0.04))
    }
}

func stepHeader(title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
        Text(title)
            .font(.system(size: 22, weight: .medium))
            .tracking(-0.2)
        Text(subtitle)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.bottom, 16)
}
