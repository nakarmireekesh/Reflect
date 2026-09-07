import XCTest
@testable import Reflect

final class EntryRetrievalTests: XCTestCase {

    private func candidate(_ text: String, daysAgo: Int) -> EntryRetrieval.Candidate {
        EntryRetrieval.Candidate(
            id: UUID(),
            text: text,
            createdAt: Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now)!
        )
    }

    func test_ranksEntriesByKeywordOverlapWithQuestion() {
        let deadline = candidate("The deadline for the demo got moved up and I felt anxious.", daysAgo: 3)
        let walk = candidate("Went for a long walk by the river, the weather was lovely.", daysAgo: 1)
        let mixed = candidate("Anxious about the demo again but a short walk helped.", daysAgo: 5)

        let picked = EntryRetrieval.selectContext(
            for: "why was I anxious about the demo?",
            from: [walk, deadline, mixed]
        )

        // Both demo/anxious entries rank above the unrelated walk entry.
        XCTAssertEqual(Array(picked.prefix(2)).map(\.id).sorted(by: { $0.uuidString < $1.uuidString }),
                       [deadline, mixed].map(\.id).sorted(by: { $0.uuidString < $1.uuidString }))
        XCTAssertFalse(picked.contains(walk))
    }

    func test_fallsBackToRecentEntriesWhenNothingMatches() {
        let entries = (0..<10).map { candidate("Ordinary day number \($0), nothing much happened.", daysAgo: $0) }

        let picked = EntryRetrieval.selectContext(
            for: "quantum chromodynamics",
            from: entries,
            recentFallbackCount: 3
        )

        XCTAssertEqual(picked.count, 3)
        XCTAssertEqual(picked.map(\.id), Array(entries.prefix(3)).map(\.id)) // most recent first
    }

    func test_emptyQuestionReturnsMostRecentWithinBudget() {
        // Each entry is 500 characters; a 1200 budget fits two.
        let entries = (0..<5).map { candidate(String(repeating: "word ", count: 100), daysAgo: $0) }

        let picked = EntryRetrieval.selectContext(for: "   ", from: entries, characterBudget: 1200)

        XCTAssertEqual(picked.map(\.id), Array(entries.prefix(2)).map(\.id))
    }

    func test_trimsToCharacterBudgetButAlwaysReturnsAtLeastOne() {
        let big = candidate(String(repeating: "a", count: 10_000), daysAgo: 0)
        let small = candidate("deadline deadline deadline", daysAgo: 1)

        let picked = EntryRetrieval.selectContext(for: "deadline", from: [small, big], characterBudget: 500)

        XCTAssertGreaterThanOrEqual(picked.count, 1)
        XCTAssertEqual(picked.first?.id, small.id)
    }

    func test_tokenizeDropsStopWordsAndShortTokens() {
        XCTAssertEqual(EntryRetrieval.tokenize("The demo was about my anxious week"),
                       ["demo", "anxious", "week"])
    }
}
