import SwiftUI

struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            if let icon = NSApp.applicationIconImage {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 96, height: 96)
            }
            Text("Welcome to Waraq")
                .font(.system(size: 28, weight: .semibold))
            Text("Bring your desktop to life with animated wallpapers.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("This quick setup walks you through choosing your displays, picking a wallpaper, and adjusting performance preferences.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
