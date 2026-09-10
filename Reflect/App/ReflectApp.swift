import SwiftData
import SwiftUI
import UIKit

@main
struct ReflectApp: App {
    init() {
        Self.applySerifNavigationTitles()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: JournalEntry.self)
    }

    /// Render navigation-bar titles in the same serif as the writing itself,
    /// so the chrome and the content feel like one piece.
    private static func applySerifNavigationTitles() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()

        if let large = UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: .largeTitle)
            .withDesign(.serif)?
            .withSymbolicTraits(.traitBold) {
            appearance.largeTitleTextAttributes[.font] = UIFont(descriptor: large, size: 0)
        }
        if let inline = UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: .headline)
            .withDesign(.serif) {
            appearance.titleTextAttributes[.font] = UIFont(descriptor: inline, size: 0)
        }

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
}

extension EnvironmentValues {
    /// The on-device intelligence service. Defaults to the real Foundation Models
    /// implementation; previews and tests substitute a stub.
    @Entry var journalIntelligence: any JournalIntelligence = FoundationModelsJournalIntelligence()
}
