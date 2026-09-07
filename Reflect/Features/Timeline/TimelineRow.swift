import SwiftUI

struct TimelineRow: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.createdAt, format: .dateTime.weekday(.wide).day().month(.wide))
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(entry.text)
                .font(.body)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            if entry.isAnalysing {
                HStack(spacing: 6) {
                    ProgressView().controlSize(.mini)
                    Text("Reflecting…").font(.caption).foregroundStyle(.secondary)
                }
            } else if entry.mood != nil || !entry.themes.isEmpty {
                HStack(spacing: 6) {
                    if let mood = entry.mood {
                        MoodPill(text: mood)
                    }
                    ForEach(entry.themes.prefix(2), id: \.self) { theme in
                        ThemeChip(text: theme)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
