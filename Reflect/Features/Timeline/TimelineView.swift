import SwiftData
import SwiftUI

struct TimelineView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.journalIntelligence) private var intelligence
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]

    @State private var composing = false

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    ContentUnavailableView {
                        Label("Nothing written yet", systemImage: "book.closed")
                    } description: {
                        Text("Your entries stay on this device. Start with whatever's on your mind.")
                    } actions: {
                        Button("New entry") { composing = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        if let reason = intelligence.availability.reason {
                            IntelligenceNotice(reason: reason)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                        ForEach(entries) { entry in
                            NavigationLink {
                                EntryEditorView(entry: entry)
                            } label: {
                                TimelineRow(entry: entry)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        composing = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel("New entry")
                }
            }
            .sheet(isPresented: $composing) {
                NavigationStack {
                    EntryEditorView(entry: nil)
                }
            }
            .task {
                // Analysis runs in a detached task that dies with the app, so a
                // flag left set by a previous launch is always stale.
                let stale = entries.filter(\.isAnalysing)
                guard !stale.isEmpty else { return }
                for entry in stale { entry.isAnalysing = false }
                try? context.save()
            }
        }
    }

    private func delete(_ offsets: IndexSet) {
        for index in offsets {
            context.delete(entries[index])
        }
    }
}

#Preview {
    TimelineView()
        .environment(\.journalIntelligence, StubJournalIntelligence.preview)
        .modelContainer(PreviewData.container)
}
