import SwiftData
import SwiftUI

/// A calm, read-only view of a saved entry. Editing is deliberate — tap the
/// pencil to open the auto-saving editor — so opening an entry to reread it
/// never risks changing it by accident.
struct EntryDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.journalIntelligence) private var intelligence
    @Environment(\.dismiss) private var dismiss

    let entry: JournalEntry

    @State private var followUpQuestion: String
    @State private var isStreaming = false
    @State private var errorMessage: String?
    @State private var editing = false

    init(entry: JournalEntry) {
        self.entry = entry
        _followUpQuestion = State(initialValue: entry.followUpPrompt ?? "")
    }

    private var isInCrisis: Bool { CrisisDetector.containsCrisisLanguage(entry.text) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                Text(entry.text)
                    .journalText(lineSpacing: 6)
                    .textSelection(.enabled)

                reflectionSection
            }
            .padding(Spacing.l)
        }
        .navigationTitle(entry.createdAt.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editing = true
                } label: {
                    Image(systemName: "pencil")
                }
                .accessibilityLabel("Edit entry")
            }
            ToolbarItem(placement: .secondaryAction) {
                Button(role: .destructive, action: deleteEntry) {
                    Label("Delete entry", systemImage: "trash")
                }
            }
        }
        .sheet(isPresented: $editing, onDismiss: {
            // Pick up anything the editor changed (text, a fresh reflection).
            followUpQuestion = entry.followUpPrompt ?? followUpQuestion
        }) {
            NavigationStack {
                EntryEditorView(entry: entry)
            }
        }
        .sensoryFeedback(trigger: followUpQuestion.isEmpty) { wasEmpty, isEmpty in
            wasEmpty && !isEmpty ? .impact(flexibility: .soft) : nil
        }
    }

    @ViewBuilder private var reflectionSection: some View {
        if isInCrisis {
            CrisisResourceView()
        } else {
            reflectionDetails
        }
    }

    @ViewBuilder private var reflectionDetails: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            Divider().opacity(0.6)

            if entry.isAnalysing {
                HStack(spacing: Spacing.s) {
                    ProgressView().controlSize(.small)
                    Text("Reflecting…").font(.footnote).foregroundStyle(.secondary)
                }
            } else if entry.mood != nil || !entry.themes.isEmpty {
                HStack(spacing: Spacing.s) {
                    if let mood = entry.mood { MoodPill(text: mood) }
                    ForEach(entry.themes, id: \.self) { ThemeChip(text: $0) }
                }
                .accessibilityElement(children: .combine)
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
            }

            if intelligence.availability.isReady {
                Button {
                    Task { await reflect() }
                } label: {
                    Label(
                        isStreaming ? "Thinking…" : (entry.mood == nil ? "Reflect on this" : "Reflect again"),
                        systemImage: "sparkles"
                    )
                    .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.brand)
                .disabled(isStreaming)
            } else if let reason = intelligence.availability.reason {
                IntelligenceNotice(reason: reason)
            }

            if let errorMessage {
                Text(errorMessage).font(.footnote).foregroundStyle(.red)
            }
        }
        .animation(.smooth(duration: 0.3), value: followUpQuestion.isEmpty)
        .animation(.smooth(duration: 0.3), value: isStreaming)
    }

    private func reflect() async {
        guard !isInCrisis else { return }
        errorMessage = nil
        followUpQuestion = ""
        isStreaming = true
        defer { isStreaming = false }
        do {
            for try await partial in intelligence.streamFollowUpQuestion(for: entry.text) {
                followUpQuestion = partial
            }
            let reflection = try await intelligence.analyse(entryText: entry.text)
            entry.mood = reflection.mood
            entry.themes = reflection.themes
            if entry.followUpPrompt == nil { entry.followUpPrompt = reflection.followUpPrompt }
            try? context.save()
        } catch is CancellationError {
            // superseded
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteEntry() {
        context.delete(entry)
        try? context.save()
        dismiss()
    }
}

#Preview {
    let entry = JournalEntry(text: "A quiet Sunday. Read on the sofa most of the afternoon.")
    entry.mood = "calm"
    entry.themes = ["rest", "reading"]
    entry.followUpPrompt = "What made today feel unhurried?"

    return NavigationStack {
        EntryDetailView(entry: entry)
    }
    .environment(\.journalIntelligence, StubJournalIntelligence.preview)
    .modelContainer(PreviewData.container)
}
