import SwiftUI

struct PerformanceStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepHeader(
                title: "Performance Settings",
                subtitle: "Waraq is built to be light. Here are some sensible defaults you can change later."
            )

            VStack(spacing: 0) {
                toggleRow(
                    title: "Pause on battery",
                    subtitle: "Saves power when your Mac is unplugged",
                    isOn: $viewModel.pauseOnBattery
                )
                Divider()
                toggleRow(
                    title: "Pause when an app goes fullscreen",
                    subtitle: "Stops rendering when you're focused on another app",
                    isOn: $viewModel.pauseOnFullscreen
                )
                Divider()
                toggleRow(
                    title: "Launch at login",
                    subtitle: "Start Waraq automatically when you log in",
                    isOn: $viewModel.launchAtLogin
                )
            }
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
            )

            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
    }

    private func toggleRow(
        title: String, subtitle: String, isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }
}
