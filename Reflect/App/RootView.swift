import SwiftUI

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            Tab("Journal", systemImage: "book.closed", value: 0) {
                TimelineView()
            }
            Tab("Insights", systemImage: "chart.bar", value: 1) {
                InsightsView()
            }
            Tab("Ask", systemImage: "sparkles", value: 2) {
                AskView()
            }
        }
        .tint(.brand)
        .sensoryFeedback(.selection, trigger: selection)
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
