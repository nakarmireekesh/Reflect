import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            Tab("Journal", systemImage: "book.closed") {
                TimelineView()
            }
            Tab("Insights", systemImage: "chart.line.uptrend.xyaxis") {
                InsightsView()
            }
            Tab("Ask", systemImage: "sparkles") {
                AskView()
            }
        }
        .tint(.accentColor)
    }
}

#Preview {
    RootView()
        .environment(\.journalIntelligence, StubJournalIntelligence.preview)
        .modelContainer(PreviewData.container)
}
