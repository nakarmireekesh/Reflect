import Charts
import SwiftData
import SwiftUI

struct InsightsView: View {
    @Environment(\.journalIntelligence) private var intelligence
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]

    @State private var digest: WeeklyDigest?
    @State private var isGenerating = false
    @State private var errorMessage: String?

    private var thisWeek: [JournalEntry] { InsightsPlanner.entriesThisWeek(entries) }
    private var themes: [(theme: String, count: Int)] { InsightsPlanner.topThemes(entries) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if entries.isEmpty {
                        ContentUnavailableView(
                            "No insights yet",
                            systemImage: "chart.line.uptrend.xyaxis",
                            description: Text("Write a few entries and patterns will show up here.")
                        )
                        .padding(.top, 60)
                    } else {
                        themesCard
                        digestCard
                    }
                }
                .padding()
            }
            .navigationTitle("Insights")
            .background(Color(.systemGroupedBackground))
        }
    }

    @ViewBuilder private var themesCard: some View {
        if !themes.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recurring themes").font(.headline)
                Chart(themes, id: \.theme) { item in
                    BarMark(
                        x: .value("Mentions", item.count),
                        y: .value("Theme", item.theme)
                    )
                    .foregroundStyle(Color.accentColor.gradient)
                    .annotation(position: .trailing) {
                        Text("\(item.count)").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .chartXAxis(.hidden)
                .frame(height: CGFloat(themes.count) * 34 + 8)
            }
            .cardStyle()
        }
    }

    @ViewBuilder private var digestCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("This week").font(.headline)
                Spacer()
                Text("^[\(thisWeek.count) entry](inflect: true)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let reason = intelligence.availability.reason {
                Text(reason).font(.footnote).foregroundStyle(.secondary)
            } else if let digest {
                Text(digest.summary)
                if !digest.highlights.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(digest.highlights, id: \.self) { highlight in
                            Label(highlight, systemImage: "circle.fill")
                                .labelStyle(BulletLabelStyle())
                        }
                    }
                    .font(.callout)
                }
                Text(digest.encouragement)
                    .font(.callout).italic()
                    .foregroundStyle(.secondary)
            } else {
                Text("Generate a gentle summary of your week from your recent entries.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            if intelligence.availability.isReady {
                Button {
                    Task { await generate() }
                } label: {
                    Label(buttonTitle, systemImage: "sparkles")
                }
                .buttonStyle(.bordered)
                .disabled(isGenerating || thisWeek.isEmpty)
            }

            if let errorMessage {
                Text(errorMessage).font(.footnote).foregroundStyle(.red)
            }
        }
        .cardStyle()
    }

    private var buttonTitle: String {
        if isGenerating { return "Reflecting on your week…" }
        return digest == nil ? "Reflect on this week" : "Refresh"
    }

    private func generate() async {
        errorMessage = nil
        isGenerating = true
        defer { isGenerating = false }
        do {
            digest = try await intelligence.weeklyDigest(from: thisWeek.map(\.text))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    InsightsView()
        .environment(\.journalIntelligence, StubJournalIntelligence.preview)
        .modelContainer(PreviewData.container)
}
