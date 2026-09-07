import SwiftData
import SwiftUI

@main
struct ReflectApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: JournalEntry.self)
    }
}

extension EnvironmentValues {
    /// The on-device intelligence service. Defaults to the real Foundation Models
    /// implementation; previews and tests substitute a stub.
    @Entry var journalIntelligence: any JournalIntelligence = FoundationModelsJournalIntelligence()
}
