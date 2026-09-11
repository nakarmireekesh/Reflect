import SwiftData
import XCTest
@testable import Reflect

@MainActor
final class JournalExporterTests: XCTestCase {

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

    private func makeEntry(
        text: String,
        createdAt: Date,
        mood: String? = nil,
        themes: [String] = []
    ) -> JournalEntry {
        let entry = JournalEntry(text: text, createdAt: createdAt)
        entry.mood = mood
        entry.themes = themes
        container.mainContext.insert(entry)
        return entry
    }

    func test_markdown_withNoEntries_saysSo() {
        XCTAssertEqual(JournalExporter.markdown(for: []), "# Reflect journal\n\nNo entries yet.\n")
    }

    func test_markdown_ordersEntriesOldestFirstAndIncludesTags() {
        let older = makeEntry(text: "Older entry", createdAt: Date(timeIntervalSince1970: 0), mood: "calm", themes: ["rest"])
        let newer = makeEntry(text: "Newer entry", createdAt: Date(timeIntervalSince1970: 1000))

        let markdown = JournalExporter.markdown(for: [newer, older])

        let olderRange = markdown.range(of: "Older entry")
        let newerRange = markdown.range(of: "Newer entry")
        XCTAssertNotNil(olderRange)
        XCTAssertNotNil(newerRange)
        XCTAssertTrue(olderRange!.lowerBound < newerRange!.lowerBound)
        XCTAssertTrue(markdown.contains("mood: calm"))
        XCTAssertTrue(markdown.contains("theme: rest"))
    }

    func test_json_withNoEntries_encodesEmptyArray() throws {
        let data = try JournalExporter.json(for: [])
        let decoded = try JSONDecoder().decode([JournalExporter.ExportedEntry].self, from: data)
        XCTAssertTrue(decoded.isEmpty)
    }

    func test_json_roundTripsEntryFields() throws {
        let entry = makeEntry(text: "A test entry", createdAt: Date(timeIntervalSince1970: 500), mood: "content", themes: ["work", "focus"])

        let data = try JournalExporter.json(for: [entry])
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode([JournalExporter.ExportedEntry].self, from: data)

        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded[0].id, entry.id)
        XCTAssertEqual(decoded[0].text, "A test entry")
        XCTAssertEqual(decoded[0].mood, "content")
        XCTAssertEqual(decoded[0].themes, ["work", "focus"])
    }
}
