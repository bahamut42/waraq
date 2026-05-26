import SwiftUI

struct PlaceholderPane: View {
    let title: String
    let phase: String
    let summary: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 22, weight: .medium))
                    .tracking(-0.2)
                    .padding(.bottom, 16)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "hammer")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.accentColor)
                        Text(phase)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.accentColor)
                    }
                    Text(summary)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineSpacing(2)
                    Text("Coming in a future session.")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.accentColor.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor.opacity(0.20), lineWidth: 0.5)
                )

                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
    }
}
