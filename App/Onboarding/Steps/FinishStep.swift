import SwiftUI

struct FinishStep: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.white, Color.green)

            Text("All Set")
                .font(.system(size: 28, weight: .semibold))

            Text("Waraq lives in your menu bar — look for the small paper icon in the top-right corner.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            // Simple visual pointing up toward the menu bar.
            HStack(spacing: 6) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 12, weight: .semibold))
                Image(systemName: "doc.fill")
                    .font(.system(size: 12))
                Text("up here, top-right")
                    .font(.system(size: 11))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.primary.opacity(0.05))
            .clipShape(Capsule())

            Text("Click it anytime to open Settings, change wallpapers, or manage displays.")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
