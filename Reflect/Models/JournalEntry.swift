import Foundation
import SwiftData

/// A single journal entry. `mood` / `themes` / `followUpPrompt` are filled in
/// asynchronously by the on-device model after the entry is saved, so they are
/// all optional / empty until analysis finishes.
@Model
final class JournalEntry {

    @Attribute(.unique) var id: UUID
    var text: String
    var createdAt: Date

    var mood: String?
    var themes: [String]
    var followUpPrompt: String?

    /// True while the on-device model is analysing this entry.
    var isAnalysing: Bool

    init(text: String, createdAt: Date = .now) {
        self.id = UUID()
        self.text = text
        self.createdAt = createdAt
        self.themes = []
        self.isAnalysing = false
    }

    var title: String {
        let firstLine = text
            .split(whereSeparator: \.isNewline)
            .first
            .map(String.init) ?? ""
        return firstLine.isEmpty ? "Untitled entry" : firstLine
    }

    var hasReflection: Bool {
        mood != nil || !themes.isEmpty || followUpPrompt != nil
    }
}
