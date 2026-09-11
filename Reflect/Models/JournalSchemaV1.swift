import Foundation
import SwiftData

/// The current (and, so far, only) shape of the journal's persisted data.
///
/// `JournalEntry` lives inside this versioned schema — rather than being a
/// bare top-level `@Model` — so that a future schema change can introduce
/// its own `JournalSchemaV2.JournalEntry` alongside a migration stage that
/// carries people's entries across, instead of silently losing them. See
/// `JournalMigrationPlan`.
///
/// Every property has a default value and `id` is no longer a unique
/// constraint: both are required by CloudKit sync, which isn't turned on
/// yet but is the reason this schema is shaped the way it is.
enum JournalSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [JournalEntry.self] }

    /// A single journal entry. `mood` / `themes` / `followUpPrompt` are filled in asynchronously by the on-device model after the entry is saved, so they are all optional / empty until analysis finishes.
    @Model
    final class JournalEntry {
        var id: UUID = UUID()
        var text: String = ""
        var createdAt: Date = Date.now

        var mood: String?
        var themes: [String] = []
        var followUpPrompt: String?

        /// True while the on-device model is analysing this entry.
        var isAnalysing: Bool = false

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
}
