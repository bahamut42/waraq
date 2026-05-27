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

struct OnboardingProgressView: View {
    let currentStep: OnboardingStep

    var body: some View {
        HStack(spacing: 10) {
            ForEach(OnboardingStep.allCases, id: \.rawValue) { step in
                Circle()
                    .fill(
                        step.rawValue <= currentStep.rawValue
                            ? Color.accentColor
                            : Color.secondary.opacity(0.3)
                    )
                    .frame(width: 8, height: 8)
                    .animation(
                        .easeInOut(duration: 0.2),
                        value: currentStep
                    )
            }
        }
    }
}
