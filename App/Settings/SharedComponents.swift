import SwiftUI

/// Grouped card surface with subtle border, used for setting groups.
struct Card<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
    }
}

/// A row inside a Card: title (+optional sublabel) on the left,
/// trailing control on the right.
struct SettingRow<Trailing: View>: View {
    let title: String
    let sublabel: String?
    @ViewBuilder let trailing: () -> Trailing

    init(
        title: String,
        sublabel: String? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.sublabel = sublabel
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13))
                if let sublabel {
                    Text(sublabel)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 12)
            trailing()
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 14)
    }
}
