import FoundationModels
import Foundation

/// `JournalIntelligence` backed by Apple's on-device model
/// (`FoundationModels`). No network, no API key — everything runs on device.
final class FoundationModelsJournalIntelligence: JournalIntelligence {

    private let model: SystemLanguageModel

    init(model: SystemLanguageModel = .default) {
        self.model = model
    }

    // MARK: - Availability

    var availability: IntelligenceAvailability {
        switch model.availability {
        case .available:
            return .ready
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                return .unavailable("This device doesn't support Apple Intelligence, so reflections are off. Your journal still works fully.")
            case .appleIntelligenceNotEnabled:
                return .unavailable("Turn on Apple Intelligence in Settings to use reflections.")
            case .modelNotReady:
                return .unavailable("The on-device model is still downloading. Reflections will switch on once it's ready.")
            @unknown default:
                return .unavailable("On-device intelligence isn't available right now.")
            }
        }
    }

    // MARK: - Requests

    func streamFollowUpQuestion(for entryText: String) -> AsyncThrowingStream<String, Error> {
        stream(instructions: Self.followUpInstructions) {
            """
            \(Self.entryBlock(entryText))

            Write exactly one gentle, open-ended follow-up question for the writer.
            """
        }
    }

    func analyse(entryText: String) async throws -> EntryReflection {
        try await run {
            let session = LanguageModelSession(model: self.model, instructions: Self.analysisInstructions)
            return try await session.respond(
                to: "\(Self.entryBlock(entryText))\n\nAnalyse this entry.",
                generating: EntryReflection.self
            ).content
        }
    }

    func weeklyDigest(from entryTexts: [String]) async throws -> WeeklyDigest {
        try await run {
            let session = LanguageModelSession(model: self.model, instructions: Self.digestInstructions)
            return try await session.respond(
                to: "This week's entries, oldest first:\n\n\(Self.numbered(entryTexts))",
                generating: WeeklyDigest.self
            ).content
        }
    }

    /// Runs a one-shot request with a hard timeout, mapping any failure to a
    /// friendly message. The on-device model can occasionally stall (e.g. while
    /// assets are still downloading) — without this the caller would wait forever.
    private func run<T: Sendable>(
        timeout: Double = 30,
        _ operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        do {
            return try await withThrowingTaskGroup(of: T.self) { group in
                group.addTask { try await operation() }
                group.addTask {
                    try await Task.sleep(for: .seconds(timeout))
                    throw IntelligenceError.message("The on-device model took too long. Make sure Apple Intelligence is turned on in Settings.")
                }
                let result = try await group.next()!
                group.cancelAll()
                return result
            }
        } catch {
            throw Self.friendlyError(error)
        }
    }

    func streamAnswer(to question: String, using entryTexts: [String]) -> AsyncThrowingStream<String, Error> {
        stream(instructions: Self.askInstructions) {
            """
            The writer's relevant past entries:

            \(Self.numbered(entryTexts))

            Their question: \(question)

            Answer in two or three sentences, warmly, referring to what they actually \
            wrote. If the entries don't contain the answer, say so kindly.
            """
        }
    }

    // MARK: - Streaming helper

    private func stream(
        instructions: String,
        prompt: @escaping @Sendable () -> String
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await withThrowingTaskGroup(of: Void.self) { group in
                        group.addTask {
                            let session = LanguageModelSession(model: self.model, instructions: instructions)
                            for try await snapshot in session.streamResponse(to: prompt()) {
                                continuation.yield(snapshot.content)
                            }
                        }
                        group.addTask {
                            try await Task.sleep(for: .seconds(30))
                            throw IntelligenceError.message("The on-device model took too long. Make sure Apple Intelligence is turned on in Settings.")
                        }
                        try await group.next()
                        group.cancelAll()
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: Self.friendlyError(error))
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - Prompt building

    private static func entryBlock(_ text: String) -> String {
        "Journal entry:\n\"\"\"\n\(text)\n\"\"\""
    }

    private static func numbered(_ texts: [String]) -> String {
        texts.enumerated()
            .map { "Entry \($0.offset + 1):\n\($0.element)" }
            .joined(separator: "\n\n")
    }

    // MARK: - Instructions (system prompts)

    private static let analysisInstructions = """
    You help someone reflect on a private journal entry. Be warm, plain-spoken and \
    non-clinical. Never diagnose. Name feelings gently. Keep every field short.
    """

    private static let followUpInstructions = """
    You are a gentle journaling companion. Given an entry, offer ONE open-ended \
    question that invites the writer to go a little deeper. No preamble, no advice, \
    just the question. Address them as "you".
    """

    private static let digestInstructions = """
    You summarise a week of private journal entries for the person who wrote them. \
    Be warm and specific, use only what they actually wrote, address them as "you", \
    and never lecture or diagnose.
    """

    private static let askInstructions = """
    You answer questions about the writer's own past journal entries, using only \
    the entries provided. Be warm, concrete and brief. If the entries don't say, \
    tell them plainly rather than guessing.
    """

    // MARK: - Error mapping

    private static func friendlyError(_ error: Error) -> Error {
        if error is CancellationError { return error }

        let notReady = "The on-device model isn't ready. Make sure Apple Intelligence is turned on in Settings, then try again."

        guard let generation = error as? LanguageModelSession.GenerationError else {
            return IntelligenceError.message(notReady)
        }
        switch generation {
        case .exceededContextWindowSize:
            return IntelligenceError.message("That was a lot to consider at once — try again with fewer entries.")
        case .guardrailViolation, .refusal:
            return IntelligenceError.message("The on-device model didn't respond to that one.")
        case .rateLimited, .concurrentRequests:
            return IntelligenceError.message("The model is busy — give it a moment and try again.")
        case .assetsUnavailable:
            return IntelligenceError.message(notReady)
        default:
            return IntelligenceError.message(notReady)
        }
    }
}
