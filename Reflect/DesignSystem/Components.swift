import SwiftUI

struct MoodPill: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.accentColor.opacity(0.15), in: Capsule())
            .foregroundStyle(Color.accentColor)
    }
}

struct ThemeChip: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.quaternary, in: Capsule())
            .foregroundStyle(.secondary)
    }
}

/// Inline notice explaining why the on-device model is unavailable.
struct IntelligenceNotice: View {
    let reason: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundStyle(.secondary)
            Text(reason)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct BulletLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
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
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
