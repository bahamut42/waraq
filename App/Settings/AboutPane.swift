import AppKit
import SwiftUI

struct AboutPane: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"]
            as? String ?? "0.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"]
            as? String ?? "1"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                hero
                links
                Divider()
                    .padding(.vertical, 18)
                    .padding(.horizontal, 40)
                acknowledgments
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 28)
        }
    }

    private var hero: some View {
        VStack(spacing: 14) {
            Image(systemName: "rectangle.stack.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 96, height: 96)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.40, blue: 0.55),
                            Color(red: 0.20, green: 0.30, blue: 0.85),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text("Waraq")
                .font(.system(size: 28, weight: .semibold))
                .tracking(-0.5)
            Text("Native macOS animated wallpaper engine")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                Text("Version \(appVersion)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("·")
                    .foregroundStyle(.tertiary)
                Text("Build \(buildNumber)")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 24)
    }

    private var links: some View {
        VStack(spacing: 10) {
            linkCard(
                icon: "person.circle.fill",
                color: .pink,
                title: "Built by Bahamüt",
                subtitle: "Omar A. Othman"
            )
            linkCard(
                icon: "doc.text.fill",
                color: .gray,
                title: "MIT License",
                subtitle: "© 2026 Omar A. Othman"
            )
            Button {
                if let url = URL(string: "https://github.com/bahamut42/waraq") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                linkCard(
                    icon: "link",
                    color: .blue,
                    title: "View on GitHub",
                    subtitle: "github.com/bahamut42/waraq"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func linkCard(
        icon: String, color: Color,
        title: String, subtitle: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 7))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var acknowledgments: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ACKNOWLEDGMENTS")
                .font(.system(size: 11, weight: .medium))
                .tracking(0.5)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 6) {
                acknowledgmentRow(
                    "Sparkle", "github.com/sparkle-project/Sparkle"
                )
                acknowledgmentRow(
                    "LaunchAtLogin", "github.com/sindresorhus/LaunchAtLogin-Modern"
                )
                acknowledgmentRow(
                    "Defaults", "github.com/sindresorhus/Defaults"
                )
            }
            Text("All MIT licensed. Thank you to the maintainers.")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func acknowledgmentRow(
        _ name: String, _ subtitle: String
    ) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 4, height: 4)
            Text(name)
                .font(.system(size: 12, weight: .medium))
            Text(subtitle)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }
}
