import SwiftUI

/// A small, consistent spacing scale so every screen breathes the same way.
enum Spacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 40
}

enum Layout {
    static let cardRadius: CGFloat = 20
    static let controlRadius: CGFloat = 14
}

extension Color {
    /// The app's accent, read straight from the asset catalog (light + dark)
    /// so it's reliable regardless of the "global accent" build setting.
    static let brand = Color("AccentColor", bundle: .main)
}

/// Serif type for the writer's own words. The rest of the app stays system sans,
/// so anything the person actually wrote (or the model wrote back) reads like a page.
private struct JournalText: ViewModifier {
    var textStyle: Font.TextStyle
    var lineSpacing: CGFloat

    func body(content: Content) -> some View {
        content
            .font(.system(textStyle, design: .serif))
            .lineSpacing(lineSpacing)
    }
}

extension View {
    func journalText(_ textStyle: Font.TextStyle = .body, lineSpacing: CGFloat = 5) -> some View {
        modifier(JournalText(textStyle: textStyle, lineSpacing: lineSpacing))
    }
}

/// Quiet, tracked-out section label used on Insights and elsewhere.
struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .tracking(0.8)
            .foregroundStyle(.secondary)
    }
}

/// Muted colours for the entry's dominant feeling. The model returns free text,
/// so moods are bucketed by keyword with a neutral fallback.
enum MoodPalette {
    static let positive = Color(red: 0.31, green: 0.49, blue: 0.42)   // calm green
    static let anxious  = Color(red: 0.69, green: 0.51, blue: 0.29)   // amber
    static let low      = Color(red: 0.37, green: 0.42, blue: 0.48)   // slate
    static let angry    = Color(red: 0.65, green: 0.36, blue: 0.31)   // rust
    static let neutral  = Color(red: 0.42, green: 0.45, blue: 0.50)   // blue-grey

    static func color(for mood: String) -> Color {
        let m = mood.lowercased()
        func has(_ words: [String]) -> Bool { words.contains { m.contains($0) } }

        if has(["anx", "stress", "worried", "worry", "overwhelm", "tense", "nervous",
                "afraid", "fear", "panic", "uneasy", "restless", "wired", "dread"]) { return anxious }
        if has(["angry", "anger", "frustrat", "irritat", "annoyed", "resent", "bitter"]) { return angry }
        if has(["sad", "down", "low", "blue", "grief", "lonely", "empty", "hopeless",
                "numb", "flat", "tired", "exhaust", "drained", "weary", "heavy"]) { return low }
        if has(["calm", "content", "peace", "relax", "settled", "grateful", "hopeful",
                "proud", "happy", "joy", "glad", "relieved", "rested", "good", "light",
                "ease", "warm", "gentle", "quiet", "clear", "clarity", "focus",
                "refresh", "renew", "open", "steady"]) { return positive }
        return neutral
    }
}

extension Date {
    /// "Today" / "Yesterday" / "Monday" / "7 September" — calm dates for the timeline.
    var journalRelative: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) { return "Today" }
        if calendar.isDateInYesterday(self) { return "Yesterday" }
        let days = calendar.dateComponents([.day], from: self, to: .now).day ?? .max
        if (0..<7).contains(days) {
            return formatted(.dateTime.weekday(.wide))
        }
        return formatted(.dateTime.day().month(.wide))
    }
}
