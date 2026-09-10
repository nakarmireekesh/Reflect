import SwiftData
import SwiftUI

struct EntryEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.journalIntelligence) private var intelligence
    @Environment(\.dismiss) private var dismiss

    let entry: JournalEntry?
    let prompt: String?

    private let originalText: String

    @State private var text: String
    @State private var draft: JournalEntry?
    @State private var followUpQuestion = ""
    @State private var isStreaming = false
    @State private var errorMessage: String?
    @State private var doneTapped = 0
    @State private var discarded = false
    @FocusState private var editorFocused: Bool

    init(entry: JournalEntry?, prompt: String? = nil) {
        self.entry = entry
        self.prompt = prompt
        self.originalText = entry?.text ?? ""
        _text = State(initialValue: entry?.text ?? "")
    }

    private var isNew: Bool { entry == nil }
    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var workingEntry: JournalEntry? { entry ?? draft }
    private var placeholder: String { prompt ?? "What's on your mind?" }

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
                            Text(placeholder)
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
            if isNew {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        doneTapped += 1
                        dismiss()
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button(role: .destructive, action: discard) {
                        Label("Discard", systemImage: "trash")
                    }
                }
            } else {
                ToolbarItem(placement: .secondaryAction) {
                    Button(role: .destructive, action: deleteEntry) {
                        Label("Delete entry", systemImage: "trash")
                    }
                }
            }
        }
        .onChange(of: text) { _, _ in syncModel() }
        .onAppear {
            followUpQuestion = workingEntry?.followUpPrompt ?? ""
            if isNew { editorFocused = true }
        }
        .onDisappear { finish() }
        .sensoryFeedback(.impact(weight: .light), trigger: doneTapped)
        .sensoryFeedback(trigger: followUpQuestion.isEmpty) { wasEmpty, isEmpty in
            wasEmpty && !isEmpty ? .impact(flexibility: .soft) : nil
        }
    }

    private var navigationTitle: String {
        if let workingEntry {
            return workingEntry.createdAt.formatted(date: .abbreviated, time: .omitted)
        }
        return "New entry"
    }

    // MARK: - Reflection

    @ViewBuilder private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            Divider().opacity(0.6)

            if let workingEntry, !workingEntry.isAnalysing,
               workingEntry.mood != nil || !workingEntry.themes.isEmpty {
                HStack(spacing: Spacing.s) {
                    if let mood = workingEntry.mood { MoodPill(text: mood) }
                    ForEach(workingEntry.themes, id: \.self) { ThemeChip(text: $0) }
                }
            }

            if !followUpQuestion.isEmpty {
                HStack(alignment: .top, spacing: Spacing.m) {
                    Rectangle()
                        .fill(Color.brand.opacity(0.35))
                        .frame(width: 2)
                    Text(followUpQuestion)
                        .journalText(lineSpacing: 4)
                        .italic()
                        .foregroundStyle(.secondary)
                        .contentTransition(.opacity)
                        .animation(.easeOut(duration: 0.12), value: followUpQuestion)
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
            .tint(.brand)
            .disabled(trimmed.isEmpty || isStreaming)

            if let errorMessage {
                Text(errorMessage).font(.footnote).foregroundStyle(.red)
            }
        }
        .animation(.smooth(duration: 0.3), value: followUpQuestion.isEmpty)
        .animation(.smooth(duration: 0.3), value: isStreaming)
    }

    /// Streams a fresh follow-up question, and re-runs the structured mood/theme
    /// analysis. Also the manual recovery path if auto-analysis didn't finish.
    private func reflect() async {
        syncModel()
        errorMessage = nil
        followUpQuestion = ""
        isStreaming = true
        defer { isStreaming = false }
        do {
            for try await partial in intelligence.streamFollowUpQuestion(for: trimmed) {
                followUpQuestion = partial
            }
            if let target = workingEntry {
                let reflection = try await intelligence.analyse(entryText: trimmed)
                target.mood = reflection.mood
                target.themes = reflection.themes
                if target.followUpPrompt == nil { target.followUpPrompt = reflection.followUpPrompt }
                try? context.save()
            }
        } catch is CancellationError {
            // superseded
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Auto-save

    /// Keeps a backing model in sync with the text as it's typed, so writing is
    /// never lost. A brand-new entry's model is created on the first character.
    private func syncModel() {
        let clean = trimmed
        if let target = workingEntry {
            target.text = clean
        } else if !clean.isEmpty {
            let created = JournalEntry(text: clean)
            context.insert(created)
            draft = created
        }
    }

    /// On close: discard an empty new entry, restore an emptied existing one,
    /// otherwise persist and kick off analysis.
    private func finish() {
        guard !discarded, let target = workingEntry else { return }
        let clean = trimmed

        if clean.isEmpty {
            if isNew {
                context.delete(target)
                draft = nil
            } else {
                target.text = originalText   // don't let a stray clear destroy an entry
            }
            try? context.save()
            return
        }

        target.text = clean
        if !followUpQuestion.isEmpty {
            target.followUpPrompt = followUpQuestion
        }

        if intelligence.availability.isReady, target.mood == nil {
            target.isAnalysing = true
            let entryText = target.text
            let id = target.persistentModelID
            Task { await analyse(entryText, entryID: id) }
        }

        try? context.save()
    }

    private func discard() {
        discarded = true
        if let target = workingEntry {
            context.delete(target)
            draft = nil
            try? context.save()
        }
        dismiss()
    }

    private func deleteEntry() {
        discarded = true
        if let entry {
            context.delete(entry)
            try? context.save()
        }
        dismiss()
    }

    /// Detached so closing the editor doesn't cancel it; the timeline updates
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
        EntryEditorView(entry: nil, prompt: "How was today?")
    }
    .environment(\.journalIntelligence, StubJournalIntelligence.preview)
    .modelContainer(PreviewData.container)
}
