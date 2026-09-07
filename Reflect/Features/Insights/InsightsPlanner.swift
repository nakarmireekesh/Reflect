import Foundation

/// Pure helpers for the Insights tab — kept out of the view so they're testable.
enum InsightsPlanner {

    /// Entries from the last 7 days, oldest first.
    static func entriesThisWeek(
        _ entries: [JournalEntry],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [JournalEntry] {
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return [] }
        return entries
            .filter { $0.createdAt >= weekAgo && $0.createdAt <= now }
            .sorted { $0.createdAt < $1.createdAt }
    }

    /// Theme → mention count, most frequent first, ties broken alphabetically.
    static func topThemes(_ entries: [JournalEntry], limit: Int = 6) -> [(theme: String, count: Int)] {
        var counts: [String: Int] = [:]
        for entry in entries {
            for theme in entry.themes {
                counts[theme.lowercased(), default: 0] += 1
            }
        }
        return counts
            .sorted { lhs, rhs in
                lhs.value != rhs.value ? lhs.value > rhs.value : lhs.key < rhs.key
            }
            .prefix(limit)
            .map { (theme: $0.key, count: $0.value) }
    }
}
