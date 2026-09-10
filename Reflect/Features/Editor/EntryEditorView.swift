import SwiftData
import SwiftUI

struct EntryEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.journalIntelligence) private var intelligence
    @Environment(\.dismiss) private var dismiss

    let entry: JournalEntry?

    @State private var text: String
    @State private var followUpQuestion = ""
    @State private var isStreaming = false
    @State private var errorMessage: String?
    @FocusState private var editorFocused: Bool

    init(entry: JournalEntry?) {
        self.entry = entry
        _text = State(initialValue: entry?.text ?? "")
    }

    private var isNew: Bool { entry == nil }
    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                TextEditor(text: $text)
                    .focused($editorFocused)
                    .journalText(lineSpacing: 6)
                    .frame(minHeight: 280)
                    .scrollContentBackground(.hidden)
                    .overlay(alignment: .topLeading) {
                        if text.isEmpty {
                            Text("What's on your mind?")
                                .journalText(lineSpacing: 6)
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }

                if intelligence.availability.isReady {
                    reflectionSection
                } else if let reason = intelligence.availability.reason {
                    IntelligenceNotice(reason: reason)
                }
            }
            .padding(Spacing.l)
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save).disabled(trimmed.isEmpty)
            }
            if isNew {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            followUpQuestion = entry?.followUpPrompt ?? ""
            if isNew { editorFocused = true }
        }
    }

    private var navigationTitle: String {
        if let entry {
            return entry.createdAt.formatted(date: .abbreviated, time: .omitted)
        }
        return "New entry"
    }

    // MARK: - Reflection

    @ViewBuilder private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            Divider().opacity(0.6)

            if let entry, !entry.isAnalysing, entry.mood != nil || !entry.themes.isEmpty {
                HStack(spacing: Spacing.s) {
                    if let mood = entry.mood { MoodPill(text: mood) }
                    ForEach(entry.themes, id: \.self) { ThemeChip(text: $0) }
                }
            }

            if !followUpQuestion.isEmpty {
                HStack(alignment: .top, spacing: Spacing.m) {
                    Rectangle()
                        .fill(Color.accentColor.opacity(0.35))
                        .frame(width: 2)
                    Text(followUpQuestion)
                        .journalText(lineSpacing: 4)
                        .italic()
                        .foregroundStyle(.secondary)
                }
                .transition(.opacity)
            }

            Button {
                Task { await reflect() }
            } label: {
                Label(isStreaming ? "Thinking…" : "Reflect on this", systemImage: "sparkles")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .tint(.accentColor)
            .disabled(trimmed.isEmpty || isStreaming)

            if let errorMessage {
                Text(errorMessage).font(.footnote).foregroundStyle(.red)
            }
        }
        .animation(.smooth(duration: 0.3), value: followUpQuestion.isEmpty)
        .animation(.smooth(duration: 0.3), value: isStreaming)
    }

    /// Streams a fresh follow-up question, and — for an already-saved entry —
    /// also re-runs the structured mood/theme analysis. This is the manual
    /// recovery path when the automatic post-save analysis didn't finish.
    private func reflect() async {
        errorMessage = nil
        followUpQuestion = ""
        isStreaming = true
        defer { isStreaming = false }
        do {
            for try await partial in intelligence.streamFollowUpQuestion(for: trimmed) {
                followUpQuestion = partial
            }
            if let entry {
                let reflection = try await intelligence.analyse(entryText: trimmed)
                entry.mood = reflection.mood
                entry.themes = reflection.themes
                if entry.followUpPrompt == nil { entry.followUpPrompt = reflection.followUpPrompt }
                try? context.save()
            }
        } catch is CancellationError {
            // superseded
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Save + background analysis

    private func save() {
        let target: JournalEntry
        if let entry {
            entry.text = trimmed
            target = entry
        } else {
            target = JournalEntry(text: trimmed)
            context.insert(target)
        }
        if !followUpQuestion.isEmpty {
            target.followUpPrompt = followUpQuestion
        }

        // Analyse in the background only when this entry has no reflection yet.
        // Re-analysing an already-tagged entry is done explicitly via "Reflect on this".
        if intelligence.availability.isReady, target.mood == nil {
            target.isAnalysing = true
            let entryText = target.text
            let id = target.persistentModelID
            Task { await analyse(entryText, entryID: id) }
        }

        try? context.save()
        dismiss()
    }

    /// Runs after the sheet is dismissed — deliberately a free `Task`, not `.task`,
    /// so closing the editor doesn't cancel the analysis. The timeline updates
    /// itself when the entry's fields change.
    private func analyse(_ entryText: String, entryID: PersistentIdentifier) async {
        guard let target = context.model(for: entryID) as? JournalEntry else { return }
        defer {
            target.isAnalysing = false
            try? context.save()
        }
        do {
            let reflection = try await intelligence.analyse(entryText: entryText)
            target.mood = reflection.mood
            target.themes = reflection.themes
            if target.followUpPrompt == nil {
                target.followUpPrompt = reflection.followUpPrompt
            }
        } catch {
            // Leave it un-analysed; the user can tap "Reflect on this" to retry.
        }
    }
}

#Preview("New") {
    NavigationStack {
        EntryEditorView(entry: nil)
    }
    .environment(\.journalIntelligence, StubJournalIntelligence.preview)
    .modelContainer(PreviewData.container)
}
