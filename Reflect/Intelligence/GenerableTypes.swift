import FoundationModels

/// Structured output for analysing a single entry. `@Generable` lets the
/// on-device model fill this in as type-safe Swift values rather than free text.
@Generable
struct EntryReflection: Equatable, Sendable {

    @Guide(description: "One or two lowercase words naming the strongest feeling in the entry, e.g. \"anxious\", \"quietly hopeful\"")
    var mood: String

    @Guide(description: "Short recurring themes in the entry, each one to three words", .count(2...3))
    var themes: [String]

    @Guide(description: "A single gentle, open-ended follow-up question, under 20 words, addressed to the writer as \"you\"")
    var followUpPrompt: String
}

/// Structured output for the weekly digest on the Insights tab.
@Generable
struct WeeklyDigest: Equatable, Sendable {

    @Guide(description: "A warm two to three sentence summary of the week, written to the person as \"you\"")
    var summary: String

    @Guide(description: "Specific moments, wins or worries the person actually mentioned this week", .count(1...3))
    var highlights: [String]

    @Guide(description: "One gentle, non-judgmental observation or piece of encouragement, one sentence")
    var encouragement: String
}
