import SwiftUI

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("isLockEnabled") private var isLockEnabled = false
    @AppStorage("isReminderEnabled") private var isReminderEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 20
    @AppStorage("reminderMinute") private var reminderMinute = 0
    @Environment(\.scenePhase) private var scenePhase

    @State private var showOnboarding = false
    @State private var selection = 0
    @State private var appLock = AppLockState()

    var body: some View {
        ZStack {
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
                if isReminderEnabled {
                    ReminderScheduler.schedule(hour: reminderHour, minute: reminderMinute)
                }
            }

            // Sits above everything, including the tab content — there's no
            // path to a locked journal without unlocking first.
            if isLockEnabled && !appLock.isUnlocked {
                LockView(appLock: appLock)
                    .transition(.opacity)
            }
        }
        .animation(.default, value: appLock.isUnlocked)
        .onChange(of: scenePhase) { _, newPhase in
            guard isLockEnabled, newPhase == .background else { return }
            appLock.lock()
        }
    }
}

#Preview {
    RootView()
        .environment(\.journalIntelligence, StubJournalIntelligence.preview)
        .modelContainer(PreviewData.container)
}
