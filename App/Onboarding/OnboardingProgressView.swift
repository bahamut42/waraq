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
