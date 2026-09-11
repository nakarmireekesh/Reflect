import Foundation

/// Looks for language suggesting someone might be in real danger, so the
/// app can offer an actual helpline instead of an AI "reflection" on it.
///
/// Deliberately a simple, over-inclusive phrase match rather than anything
/// clever: a false positive just shows a helpline unnecessarily, but a
/// false negative could matter, so this errs toward triggering too often.
enum CrisisDetector {
    static let phrases: [String] = [
        "kill myself", "killing myself", "kill me",
        "want to die", "wanted to die", "wish i was dead", "wish i were dead",
        "end it all", "end my life", "ending my life",
        "take my own life", "ending my own life",
        "no reason to live", "no point in living", "not worth living",
        "don't want to be here", "do not want to be here",
        "don't want to live", "do not want to live",
        "better off dead", "can't go on", "cannot go on",
        "suicidal", "suicide",
        "self-harm", "self harm",
        "hurting myself", "hurt myself", "cutting myself", "cut myself",
    ]

    static func containsCrisisLanguage(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }
        let normalized = text.lowercased()
        return phrases.contains { normalized.contains($0) }
    }
}
