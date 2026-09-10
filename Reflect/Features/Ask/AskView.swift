import SwiftData
import SwiftUI

struct AskView: View {
    @Environment(\.journalIntelligence) private var intelligence
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]

    @State private var question = ""
    @State private var answer = ""
    @State private var usedEntries: [JournalEntry] = []
    @State private var isStreaming = false
    @State private var errorMessage: String?
    @FocusState private var fieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.l) {
                        Text("Ask about anything you've written. Your entries never leave this device.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        if let reason = intelligence.availability.reason {
                            IntelligenceNotice(reason: reason)
                        }

                        if !usedEntries.isEmpty {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                SectionHeader(title: "Looking at")
                                ForEach(usedEntries) { entry in
                                    Text("\(entry.createdAt.journalRelative) · \(entry.title)")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                        .lineLimit(1)
                                }
                            }
                        }

                        if isStreaming && answer.isEmpty {
                            ProgressView().padding(.top, Spacing.xs)
                        }
                        if !answer.isEmpty {
                            Text(answer)
                                .journalText(lineSpacing: 5)
                                .textSelection(.enabled)
                        }
                        if let errorMessage {
                            Text(errorMessage).font(.footnote).foregroundStyle(.red)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.l)
                }
                .scrollDismissesKeyboard(.interactively)
                .animation(.smooth(duration: 0.25), value: usedEntries.count)

                inputBar
            }
            .navigationTitle("Ask")
        }
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 10) {
                TextField("What was I worried about last month?", text: $question)
                    .textFieldStyle(.roundedBorder)
                    .focused($fieldFocused)
                    .submitLabel(.send)
                    .disabled(!intelligence.availability.isReady)
                    .onSubmit { Task { await ask() } }

                Button {
                    Task { await ask() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill").font(.title)
                }
                .disabled(!canAsk)
                .accessibilityLabel("Ask")
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(.bar)
    }

    private var canAsk: Bool {
        !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isStreaming
            && intelligence.availability.isReady
    }

    private func ask() async {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        fieldFocused = false
        errorMessage = nil
        answer = ""
        isStreaming = true
        defer { isStreaming = false }

        let candidates = entries.map {
            EntryRetrieval.Candidate(id: $0.id, text: $0.text, createdAt: $0.createdAt)
        }
        let selected = EntryRetrieval.selectContext(for: trimmed, from: candidates)
        let selectedIDs = Set(selected.map(\.id))
        usedEntries = entries.filter { selectedIDs.contains($0.id) }

        do {
            for try await partial in intelligence.streamAnswer(to: trimmed, using: selected.map(\.text)) {
                answer = partial
            }
        } catch is CancellationError {
            // superseded
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    AskView()
        .environment(\.journalIntelligence, StubJournalIntelligence.preview)
        .modelContainer(PreviewData.container)
}
