import SwiftData
import SwiftUI

struct TimelineView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.journalIntelligence) private var intelligence
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]

    @State private var composing = false
    @State private var newEntryPrompt: String?
    @State private var showingSettings = false
    @State private var promptRotator = PromptRotator(pool: Self.starterPrompts, count: 3)

    private static let starterPrompts = [
        "How was today?",
        "What's on your mind right now?",
        "One thing I noticed today…",
        "What's weighing on you?",
        "What went better than expected?",
        "Something you're grateful for?",
        "What's been on repeat in your head?",
        "Describe today in one feeling.",
        "What would make tomorrow better?",
    ]

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    firstRun
                } else {
                    entryList
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        newEntryPrompt = nil
                        composing = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel("New entry")
                }
            }
            .sheet(isPresented: $composing) {
                NavigationStack {
                    EntryEditorView(entry: nil, prompt: newEntryPrompt)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
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

    // MARK: - First run

    private var firstRun: some View {
        VStack(spacing: Spacing.xl) {
            VStack(spacing: Spacing.m) {
                Text("Start your journal")
                    .font(.system(.title, design: .serif).weight(.semibold))
                Text("Your entries stay on this iPhone. Write whatever's on your mind.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: Spacing.s) {
                ForEach(promptRotator.current, id: \.self) { prompt in
                    Button {
                        newEntryPrompt = prompt
                        composing = true
                    } label: {
                        Text(prompt)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.s + 2)
                    }
                    .buttonStyle(.bordered)
                    .tint(.brand)
                    .transition(.opacity)
                }

                Button("Blank page") {
                    newEntryPrompt = nil
                    composing = true
                }
                .font(.callout)
                .padding(.top, Spacing.xs)
            }
            .frame(maxWidth: 320)
        }
        .padding(Spacing.xl)
        .task { await promptRotator.start() }
    }

    // MARK: - Entry list

    private var entryList: some View {
        List {
            if let reason = intelligence.availability.reason {
                IntelligenceNotice(reason: reason)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: Spacing.s, leading: Spacing.l, bottom: Spacing.m, trailing: Spacing.l))
            }

            if let onThisDay {
                OnThisDayCard(entry: onThisDay)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: Spacing.s, leading: Spacing.l, bottom: Spacing.m, trailing: Spacing.l))
            }

            ForEach(months) { section in
                Section {
                    ForEach(section.entries) { entry in
                        NavigationLink {
                            EntryDetailView(entry: entry)
                        } label: {
                            TimelineRow(entry: entry)
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: Spacing.m, leading: Spacing.l, bottom: Spacing.m, trailing: Spacing.l))
                    }
                    .onDelete { delete($0, in: section.entries) }
                } header: {
                    Text(section.title)
                        .font(.system(.subheadline, design: .serif).weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }
            }
        }
        .listStyle(.plain)
        .animation(.smooth, value: entries.count)
    }

    private var months: [MonthSection] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.date(from: calendar.dateComponents([.year, .month], from: entry.createdAt)) ?? entry.createdAt
        }
        return grouped
            .map { MonthSection(month: $0.key, entries: $0.value.sorted { $0.createdAt > $1.createdAt }) }
            .sorted { $0.month > $1.month }
    }

    private var onThisDay: JournalEntry? {
        TimelinePlanner.onThisDay(from: entries)
    }

    private func delete(_ offsets: IndexSet, in monthEntries: [JournalEntry]) {
        withAnimation(.smooth) {
            for index in offsets {
                context.delete(monthEntries[index])
            }
        }
    }
}

private struct MonthSection: Identifiable {
    let month: Date
    let entries: [JournalEntry]

    var id: Date { month }

    var title: String {
        let calendar = Calendar.current
        if calendar.isDate(month, equalTo: .now, toGranularity: .month) { return "This month" }
        let sameYear = calendar.isDate(month, equalTo: .now, toGranularity: .year)
        return month.formatted(sameYear ? .dateTime.month(.wide) : .dateTime.month(.wide).year())
    }
}

private struct OnThisDayCard: View {
    let entry: JournalEntry

    var body: some View {
        NavigationLink {
            EntryDetailView(entry: entry)
        } label: {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Label("On this day", systemImage: "clock.arrow.circlepath")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.brand)
                Text(entry.createdAt.formatted(.dateTime.year().month(.wide).day()))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(entry.text)
                    .journalText(.subheadline, lineSpacing: 3)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    TimelineView()
        .environment(\.journalIntelligence, StubJournalIntelligence.preview)
        .modelContainer(PreviewData.container)
}
