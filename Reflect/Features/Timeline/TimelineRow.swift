import SwiftUI

struct TimelineRow: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(entry.createdAt.journalRelative)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text(entry.text)
                .journalText(lineSpacing: 4)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            if entry.isAnalysing {
                HStack(spacing: Spacing.s) {
                    ProgressView().controlSize(.mini)
                    Text("Reflecting…").font(.caption).foregroundStyle(.tertiary)
                }
                .transition(.opacity)
            } else if let mood = entry.mood {
                MoodPill(text: mood)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .padding(.vertical, Spacing.xs)
        .animation(.smooth(duration: 0.25), value: entry.isAnalysing)
        .animation(.smooth(duration: 0.25), value: entry.mood)
    }
}
