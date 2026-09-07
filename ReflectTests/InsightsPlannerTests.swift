import SwiftData
import XCTest
@testable import Reflect

@MainActor
final class InsightsPlannerTests: XCTestCase {

    private var container: ModelContainer!

    override func setUpWithError() throws {
        try super.setUpWithError()
        container = try ModelContainer(
            for: JournalEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    override func tearDownWithError() throws {
        container = nil
        try super.tearDownWithError()
    }

    private func makeEntry(daysAgo: Int, themes: [String] = []) -> JournalEntry {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now)!
        let entry = JournalEntry(text: "Entry from \(daysAgo) days ago", createdAt: date)
        entry.themes = themes
        container.mainContext.insert(entry)
        return entry
    }

    func test_entriesThisWeek_keepsLastSevenDaysOldestFirst() {
        _ = makeEntry(daysAgo: 10)
        let sixDays = makeEntry(daysAgo: 6)
        let twoDays = makeEntry(daysAgo: 2)
        let today = makeEntry(daysAgo: 0)

        let week = InsightsPlanner.entriesThisWeek([today, twoDays, sixDays])

        XCTAssertEqual(week.map(\.createdAt), [sixDays, twoDays, today].map(\.createdAt))
    }

    func test_topThemes_countsCaseInsensitivelyAndOrdersByFrequency() {
        let entries = [
            makeEntry(daysAgo: 1, themes: ["Work", "sleep"]),
            makeEntry(daysAgo: 2, themes: ["work", "family"]),
            makeEntry(daysAgo: 3, themes: ["WORK"]),
            makeEntry(daysAgo: 4, themes: ["sleep"]),
        ]

        let top = InsightsPlanner.topThemes(entries, limit: 3)

        XCTAssertEqual(top.map(\.theme), ["work", "sleep", "family"])
        XCTAssertEqual(top.map(\.count), [3, 2, 1])
    }
}
