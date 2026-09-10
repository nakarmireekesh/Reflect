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
