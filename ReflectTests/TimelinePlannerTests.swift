import SwiftData
import XCTest
@testable import Reflect

@MainActor
final class TimelinePlannerTests: XCTestCase {

    private var container: ModelContainer!
    private let calendar = Calendar(identifier: .gregorian)

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

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func makeEntry(on createdAt: Date, text: String = "entry") -> JournalEntry {
        let entry = JournalEntry(text: text, createdAt: createdAt)
        container.mainContext.insert(entry)
        return entry
    }

    func test_findsEntryFromExactlyOneYearAgoOnTheSameDay() {
        let now = date(2026, 9, 11)
        let lastYear = makeEntry(on: date(2025, 9, 11), text: "last year")

        let result = TimelinePlanner.onThisDay(from: [lastYear], now: now, calendar: calendar)

        XCTAssertEqual(result?.text, "last year")
    }

    func test_ignoresAnEntryFromToday() {
        let now = date(2026, 9, 11)
        let today = makeEntry(on: now)

        let result = TimelinePlanner.onThisDay(from: [today], now: now, calendar: calendar)

        XCTAssertNil(result)
    }

    func test_ignoresEntriesFromADifferentMonthOrDay() {
        let now = date(2026, 9, 11)
        let sameDayDifferentMonth = makeEntry(on: date(2025, 8, 11))
        let sameMonthDifferentDay = makeEntry(on: date(2025, 9, 10))

        let result = TimelinePlanner.onThisDay(
            from: [sameDayDifferentMonth, sameMonthDifferentDay],
            now: now,
            calendar: calendar
        )

        XCTAssertNil(result)
    }

    func test_returnsTheMostRecentMatchWhenSeveralYearsQualify() {
        let now = date(2026, 9, 11)
        let twoYearsAgo = makeEntry(on: date(2024, 9, 11), text: "two years ago")
        let oneYearAgo = makeEntry(on: date(2025, 9, 11), text: "one year ago")

        let result = TimelinePlanner.onThisDay(from: [twoYearsAgo, oneYearAgo], now: now, calendar: calendar)

        XCTAssertEqual(result?.text, "one year ago")
    }

    func test_returnsNilWhenNothingMatches() {
        let now = date(2026, 9, 11)
        let unrelated = makeEntry(on: date(2025, 3, 4))

        let result = TimelinePlanner.onThisDay(from: [unrelated], now: now, calendar: calendar)

        XCTAssertNil(result)
    }
}
