import XCTest
@testable import Reflect

final class StubJournalIntelligenceTests: XCTestCase {

    func test_streamFollowUpQuestion_yieldsCumulativeText() async throws {
        let stub = StubJournalIntelligence(followUpChunks: ["Hello ", "there ", "friend"])

        var snapshots: [String] = []
        for try await partial in stub.streamFollowUpQuestion(for: "entry") {
            snapshots.append(partial)
        }

        XCTAssertEqual(snapshots, ["Hello ", "Hello there ", "Hello there friend"])
    }

    func test_analyse_recordsInputAndReturnsConfiguredReflection() async throws {
        let reflection = EntryReflection(mood: "calm", themes: ["a", "b"], followUpPrompt: "q?")
        let stub = StubJournalIntelligence(reflection: reflection)

        let result = try await stub.analyse(entryText: "today was fine")

        XCTAssertEqual(result, reflection)
        XCTAssertEqual(stub.analysedTexts, ["today was fine"])
    }

    func test_weeklyDigest_recordsTheEntriesItWasGiven() async throws {
        let stub = StubJournalIntelligence()

        _ = try await stub.weeklyDigest(from: ["mon", "tue", "wed"])

        XCTAssertEqual(stub.digestInputs, [["mon", "tue", "wed"]])
    }

    func test_unavailableStub_reportsReason() {
        let stub = StubJournalIntelligence(availability: .unavailable("nope"))

        XCTAssertFalse(stub.availability.isReady)
        XCTAssertEqual(stub.availability.reason, "nope")
    }
}
