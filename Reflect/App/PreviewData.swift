import Foundation
import SwiftData

@MainActor
enum PreviewData {

    static let container: ModelContainer = {
        let container = try! ModelContainer(
            for: JournalEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        for entry in samples {
            container.mainContext.insert(entry)
        }
        return container
    }()

    private static var samples: [JournalEntry] {
        [
            make(daysAgo: 0, "Slept badly again but the morning walk helped. Work is loud in my head and I keep replaying the standup.",
                 mood: "wired", themes: ["sleep", "work"]),
            make(daysAgo: 2, "Good call with mum. Actually cooked properly for the first time this week and it felt like taking care of myself.",
                 mood: "settled", themes: ["family", "home"]),
            make(daysAgo: 5, "Deadline moved up. Spent the evening anxious about the demo and didn't really switch off.",
                 mood: "anxious", themes: ["deadline", "work"]),
            make(daysAgo: 9, "Long weekend. Read a whole book, didn't check email once. Forgot how much I like being bored.",
                 mood: "rested", themes: ["rest", "reading"]),
        ]
    }

    private static func make(daysAgo: Int, _ text: String, mood: String, themes: [String]) -> JournalEntry {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
        let entry = JournalEntry(text: text, createdAt: date)
        entry.mood = mood
        entry.themes = themes
        entry.followUpPrompt = "What would help the next hard evening feel a little easier?"
        return entry
    }
}
