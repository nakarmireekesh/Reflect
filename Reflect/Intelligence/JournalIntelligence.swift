import Foundation

enum IntelligenceAvailability: Equatable, Sendable {
    case ready
    case unavailable(String)

    var isReady: Bool { self == .ready }

    var reason: String? {
        if case .unavailable(let reason) = self { return reason }
        return nil
    }
}

enum IntelligenceError: LocalizedError {
    case message(String)

    var errorDescription: String? {
        switch self {
        case .message(let text): return text
        }
    }
}

protocol JournalIntelligence: Sendable {

    var availability: IntelligenceAvailability { get }

    /// Streams a gentle follow-up question for an entry. Each value is the full text generated so far.
    func streamFollowUpQuestion(for entryText: String) -> AsyncThrowingStream<String, Error>

    /// One-shot structured analysis of a single entry.
    func analyse(entryText: String) async throws -> EntryReflection

    /// A digest built from several entries (typically the last seven days).
    func weeklyDigest(from entryTexts: [String]) async throws -> WeeklyDigest

    /// Streams an answer to a free-text question, grounded in the given entries.
    func streamAnswer(to question: String, using entryTexts: [String]) -> AsyncThrowingStream<String, Error>
}
