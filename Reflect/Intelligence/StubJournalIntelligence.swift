import Foundation

/// Deterministic `JournalIntelligence` for SwiftUI previews and unit tests — no model, no delay-free streaming that mimics the real token stream.
final class StubJournalIntelligence: JournalIntelligence, @unchecked Sendable {

    var availability: IntelligenceAvailability
    var reflection: EntryReflection
    var digest: WeeklyDigest
    var answerChunks: [String]
    var followUpChunks: [String]

    private(set) var analysedTexts: [String] = []
    private(set) var digestInputs: [[String]] = []
    private(set) var answerContexts: [[String]] = []

    init(
        availability: IntelligenceAvailability = .ready,
        reflection: EntryReflection = EntryReflection(
            mood: "reflective",
            themes: ["work", "rest"],
            followUpPrompt: "What would a lighter version of tomorrow look like?"
        ),
        digest: WeeklyDigest = WeeklyDigest(
            summary: "You had a full week and still made room to notice small good things.",
            highlights: ["Finished the project", "A long walk on Wednesday"],
            encouragement: "Resting is part of the work."
        ),
        answerChunks: [String] = ["You mentioned ", "feeling calmer ", "after the walk on Wednesday."],
        followUpChunks: [String] = ["What part of today ", "do you want to carry ", "into tomorrow?"]
    ) {
        self.availability = availability
        self.reflection = reflection
        self.digest = digest
        self.answerChunks = answerChunks
        self.followUpChunks = followUpChunks
    }

    static var preview: StubJournalIntelligence { StubJournalIntelligence() }

    func streamFollowUpQuestion(for entryText: String) -> AsyncThrowingStream<String, Error> {
        Self.cumulativeStream(followUpChunks)
    }

    func analyse(entryText: String) async throws -> EntryReflection {
        analysedTexts.append(entryText)
        return reflection
    }

    func weeklyDigest(from entryTexts: [String]) async throws -> WeeklyDigest {
        digestInputs.append(entryTexts)
        return digest
    }

    func streamAnswer(to question: String, using entryTexts: [String]) -> AsyncThrowingStream<String, Error> {
        answerContexts.append(entryTexts)
        return Self.cumulativeStream(answerChunks)
    }

    private static func cumulativeStream(_ chunks: [String]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                var accumulated = ""
                for chunk in chunks {
                    accumulated += chunk
                    continuation.yield(accumulated)
                    try? await Task.sleep(for: .milliseconds(80))
                }
                continuation.finish()
            }
        }
    }
}
