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

struct OnboardingRootView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            OnboardingProgressView(currentStep: viewModel.currentStep)
                .padding(.top, 24)
                .padding(.bottom, 20)

            Group {
                switch viewModel.currentStep {
                case .welcome:
                    WelcomeStep()
                case .displays:
                    DisplaysStep(displayManager: viewModel.displayManager)
                case .wallpaper:
                    WallpaperStep(viewModel: viewModel)
                case .performance:
                    PerformanceStep(viewModel: viewModel)
                case .finish:
                    FinishStep()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 40)
            .animation(.easeInOut(duration: 0.2), value: viewModel.currentStep)

            Divider()

            footer
        }
        .frame(width: 640, height: 520)
    }

    private var footer: some View {
        HStack {
            Button("Skip") {
                viewModel.skip()
                onDismiss()
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)

            Spacer()

            if viewModel.canGoBack {
                Button("Back") { viewModel.back() }
                    .keyboardShortcut(.leftArrow, modifiers: [])
            }

            if viewModel.isLastStep {
                Button("Done") {
                    viewModel.finish()
                    onDismiss()
                }
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
            } else {
                Button("Next") { viewModel.next() }
                    .keyboardShortcut(.defaultAction)
                    .controlSize(.large)
            }
        }
        .padding(20)
    }
}
