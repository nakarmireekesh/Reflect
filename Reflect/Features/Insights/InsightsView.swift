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
                if entries.isEmpty {
                    emptyState
                } else {
                    VStack(alignment: .leading, spacing: 22) {
                        themesCard
                        digestCard
                    }
                    .padding()
                }
            }
            .navigationTitle("Insights")
            .background(Color(.systemGroupedBackground))
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.m) {
            Image(systemName: "chart.bar")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.tertiary)
            Text("No insights yet")
                .font(.system(.title3, design: .serif).weight(.semibold))
            Text("Write a few entries and patterns will show up here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: 320)
        .padding(.top, 100)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private var themesCard: some View {
        if !themes.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.m) {
                SectionHeader(title: "Recurring themes")
                Chart(themes, id: \.theme) { item in
                    BarMark(
                        x: .value("Mentions", item.count),
                        y: .value("Theme", item.theme),
                        height: .fixed(10)
                    )
                    .foregroundStyle(Color.brand.opacity(0.85))
                    .cornerRadius(5)
                    .annotation(position: .trailing) {
                        Text("\(item.count)").font(.caption2).foregroundStyle(.tertiary)
                    }
                }
                .chartXAxis(.hidden)
                .frame(height: CGFloat(themes.count) * 30 + 4)
                // The chart's fixed row height can't grow with the text, so the
                // axis labels are capped short of the accessibility sizes that
                // would otherwise overlap the bars.
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            }
            .cardStyle()
        }
    }

    @ViewBuilder private var digestCard: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack {
                SectionHeader(title: "This week")
                Spacer()
                Text("^[\(thisWeek.count) entry](inflect: true)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            if let reason = intelligence.availability.reason {
                Text(reason).font(.footnote).foregroundStyle(.secondary)
            } else if let digest {
                Text(digest.summary)
                    .journalText(lineSpacing: 5)
                    .transition(.opacity)
                if !digest.highlights.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        ForEach(digest.highlights, id: \.self) { highlight in
                            Label(highlight, systemImage: "circle.fill")
                                .labelStyle(BulletLabelStyle())
                        }
                    }
                    .font(.callout)
                }
                Text(digest.encouragement)
                    .journalText(.callout, lineSpacing: 4).italic()
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
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.brand)
                .disabled(isGenerating || thisWeek.isEmpty)
            }

            if let errorMessage {
                Text(errorMessage).font(.footnote).foregroundStyle(.red)
            }
        }
        .animation(.smooth(duration: 0.3), value: digest)
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
