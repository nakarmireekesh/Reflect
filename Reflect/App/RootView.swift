import SwiftUI

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false

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
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                showOnboarding = false
                hasCompletedOnboarding = true
            }
        }
        .onAppear {
            showOnboarding = !hasCompletedOnboarding
        }
    }
}

#Preview {
    RootView()
        .environment(\.journalIntelligence, StubJournalIntelligence.preview)
        .modelContainer(PreviewData.container)
}
