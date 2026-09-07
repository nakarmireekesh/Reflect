import Foundation

/// Picks which past entries to feed the model when answering a question.
/// The on-device model has a small context window, so can't send everything.
/// This ranks entries by keyword overlap with the question, falls back to the most recent entries when nothing matches, and trims the result to a character budget. Pure and synchronous so it can be unit-tested without the model.

enum EntryRetrieval {

    struct Candidate: Equatable {
        let id: UUID
        let text: String
        let createdAt: Date
    }

    static func selectContext(
        for question: String,
        from entries: [Candidate],
        characterBudget: Int = 6000,
        recentFallbackCount: Int = 4
    ) -> [Candidate] {
        let questionTokens = Set(tokenize(question))

        let ranked: [Candidate]
        if questionTokens.isEmpty {
            ranked = entries.sorted { $0.createdAt > $1.createdAt }
        } else {
            let scored = entries.map { entry -> (Candidate, Int) in
                let overlap = tokenize(entry.text).reduce(into: 0) { partial, token in
                    if questionTokens.contains(token) { partial += 1 }
                }
                return (entry, overlap)
            }
            let matches = scored
                .filter { $0.1 > 0 }
                .sorted { lhs, rhs in
                    lhs.1 != rhs.1 ? lhs.1 > rhs.1 : lhs.0.createdAt > rhs.0.createdAt
                }
                .map(\.0)

            ranked = matches.isEmpty
                ? Array(entries.sorted { $0.createdAt > $1.createdAt }.prefix(recentFallbackCount))
                : matches
        }

        var used = 0
        var picked: [Candidate] = []
        for entry in ranked {
            let next = used + entry.text.count
            if !picked.isEmpty && next > characterBudget { break }
            picked.append(entry)
            used = next
            if used >= characterBudget { break }
        }
        return picked
    }

    static func tokenize(_ string: String) -> [String] {
        string
            .lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .filter { $0.count > 2 && !stopWords.contains($0) }
    }

    private static let stopWords: Set<String> = [
        "the", "and", "for", "was", "with", "that", "this", "you", "your",
        "have", "had", "not", "but", "are", "were", "did", "does", "about",
        "what", "when", "why", "how", "who", "which", "been", "from",
    ]
}
