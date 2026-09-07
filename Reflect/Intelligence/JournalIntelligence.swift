import Foundation

/// Whether the on-device model can be used right now, plus a user-facing reason
/// when it can't. The app is fully usable as a journal either way — only the
/// reflection features switch off.
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

/// Everything the app asks of the on-device language model, behind a protocol so
/// the UI can be driven by a stub in tests and previews.
protocol JournalIntelligence: Sendable {

    var availability: IntelligenceAvailability { get }

    /// Streams a gentle follow-up question for an entry. Each value is the full
    /// text generated so far.
    func streamFollowUpQuestion(for entryText: String) -> AsyncThrowingStream<String, Error>

    /// One-shot structured analysis of a single entry.
    func analyse(entryText: String) async throws -> EntryReflection

    /// A digest built from several entries (typically the last seven days).
    func weeklyDigest(from entryTexts: [String]) async throws -> WeeklyDigest

    /// Streams an answer to a free-text question, grounded in the given entries.
    func streamAnswer(to question: String, using entryTexts: [String]) -> AsyncThrowingStream<String, Error>
}
