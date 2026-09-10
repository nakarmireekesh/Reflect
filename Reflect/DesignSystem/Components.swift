import SwiftUI

/// A small tint of colour for the entry's dominant feeling.
struct MoodPill: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, Spacing.s)
            .padding(.vertical, 3)
            .background(Color.accentColor.opacity(0.12), in: Capsule())
            .foregroundStyle(Color.accentColor)
    }
}

struct ThemeChip: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, Spacing.s)
            .padding(.vertical, 3)
            .overlay(Capsule().strokeBorder(.quaternary))
            .foregroundStyle(.secondary)
    }
}

/// Inline notice explaining why the on-device model is unavailable.
struct IntelligenceNotice: View {
    let reason: String
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            Image(systemName: "sparkles")
                .foregroundStyle(.tertiary)
            Text(reason)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Layout.controlRadius))
    }
}

struct BulletLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
            configuration.icon
                .font(.system(size: 5))
                .foregroundStyle(.tertiary)
            configuration.title
        }
    }
}

extension View {
    /// Standard rounded card container used on the Insights tab.
    func cardStyle() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.l)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Layout.cardRadius))
    }
}
