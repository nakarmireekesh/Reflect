import Foundation

/// Pure helpers for the Journal tab — kept out of the view so they're testable.
enum TimelinePlanner {

    /// The most recent past entry written on this same day of the year, if any —
    /// a small on-device "memories" touch, à la Photos. `nil` when nothing from
    /// a previous year (or an earlier occurrence) shares today's month and day.
    static func onThisDay(
        from entries: [JournalEntry],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> JournalEntry? {
        let today = calendar.dateComponents([.month, .day], from: now)
        return entries
            .filter { entry in
                !calendar.isDate(entry.createdAt, inSameDayAs: now)
                    && calendar.dateComponents([.month, .day], from: entry.createdAt) == today
            }
            .max { $0.createdAt < $1.createdAt }
    }
}
