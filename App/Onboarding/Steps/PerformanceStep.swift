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
