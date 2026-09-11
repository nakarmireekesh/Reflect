import Foundation

/// Turns the journal into a portable file — Markdown to read, JSON to keep
/// as data. Pure and file-I/O-free so it's testable; SettingsView is the
/// only thing that actually touches the filesystem.
enum JournalExporter {

    struct ExportedEntry: Codable, Equatable {
        let id: UUID
        let createdAt: Date
        let text: String
        let mood: String?
        let themes: [String]
        let followUpPrompt: String?
    }

    static func markdown(for entries: [JournalEntry]) -> String {
        guard !entries.isEmpty else {
            return "# Reflect journal\n\nNo entries yet.\n"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short

        var lines = [
            "# Reflect journal",
            "",
            "Exported \(entries.count) \(entries.count == 1 ? "entry" : "entries").",
            "",
        ]

        for entry in entries.sorted(by: { $0.createdAt < $1.createdAt }) {
            lines.append("## \(formatter.string(from: entry.createdAt))")
            lines.append("")
            lines.append(entry.text)

            var tags: [String] = []
            if let mood = entry.mood { tags.append("mood: \(mood)") }
            tags.append(contentsOf: entry.themes.map { "theme: \($0)" })
            if !tags.isEmpty {
                lines.append("")
                lines.append("_\(tags.joined(separator: " \u{00B7} "))_")
            }
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    static func json(for entries: [JournalEntry]) throws -> Data {
        let exportable = entries
            .sorted { $0.createdAt < $1.createdAt }
            .map {
                ExportedEntry(
                    id: $0.id,
                    createdAt: $0.createdAt,
                    text: $0.text,
                    mood: $0.mood,
                    themes: $0.themes,
                    followUpPrompt: $0.followUpPrompt
                )
            }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(exportable)
    }
}
