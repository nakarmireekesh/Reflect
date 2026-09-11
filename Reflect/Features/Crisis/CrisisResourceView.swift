import SwiftUI
import UIKit

/// Shown in place of the AI reflection when an entry's text matches
/// `CrisisDetector`. Calm, non-alarming, and never blocks the person from
/// continuing to write — it's an offer, not a gate.
struct CrisisResourceView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            Divider().opacity(0.6)

            VStack(alignment: .leading, spacing: Spacing.s) {
                Label("You don't have to carry this alone", systemImage: "lifepreserver")
                    .font(.system(.subheadline, design: .serif).weight(.semibold))
                    .foregroundStyle(Color.brand)
                Text("What you wrote sounds really heavy. Reflect can't help the way a person can, but these are here if you want someone to talk to.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: Spacing.s) {
                CrisisResourceRow(
                    title: "Samaritans",
                    subtitle: "Free, 24/7, for anyone struggling.",
                    action: "Call 116 123",
                    copyValue: "116123",
                    url: URL(string: "tel:116123")
                )
                CrisisResourceRow(
                    title: "Shout",
                    subtitle: "Free, 24/7 crisis text support. Text \u{201C}SHOUT\u{201D}.",
                    action: "Text 85258",
                    copyValue: "85258",
                    url: URL(string: "sms:85258")
                )
                CrisisResourceRow(
                    title: "Emergency services",
                    subtitle: "If you or someone else is in immediate danger.",
                    action: "Call 999",
                    copyValue: "999",
                    url: URL(string: "tel:999")
                )
            }

            Text("Outside the UK? Most countries have a local crisis line — it's worth searching for one.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .transition(.opacity)
    }
}

private struct CrisisResourceRow: View {
    let title: String
    let subtitle: String
    let action: String
    let copyValue: String
    let url: URL?

    @State private var showCopyFallback = false

    var body: some View {
        Button(action: open) {
            HStack(alignment: .top, spacing: Spacing.m) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(action)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.brand)
                    .multilineTextAlignment(.trailing)
                    .layoutPriority(1)
            }
        }
        .buttonStyle(.plain)
        .padding(Spacing.m)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Layout.controlRadius))
        .confirmationDialog("Couldn't open that automatically", isPresented: $showCopyFallback) {
            Button("Copy \(copyValue)") { UIPasteboard.general.string = copyValue }
        }
        .accessibilityElement(children: .combine)
    }

    private func open() {
        guard let url else { return }
        UIApplication.shared.open(url) { success in
            if !success { showCopyFallback = true }
        }
    }
}

#Preview {
    ScrollView {
        CrisisResourceView()
            .padding()
    }
}
