import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void

    @State private var index = 0

    private let pages: [Page] = [
        Page(
            symbol: "book.closed",
            title: "A journal that reflects with you",
            body: "Write freely. When you're done, your iPhone offers a gentle question to sit with."
        ),
        Page(
            symbol: "lock",
            title: "Yours alone",
            body: "Every entry stays on this iPhone. No account, no cloud, no one else — ever."
        ),
        Page(
            symbol: "sparkles",
            title: "Thinks on device",
            body: "Mood, themes and weekly summaries are written by Apple Intelligence, entirely offline."
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $index) {
                ForEach(Array(pages.enumerated()), id: \.offset) { offset, page in
                    pageView(page).tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack(spacing: Spacing.l) {
                PageDots(count: pages.count, index: index)

                Button(isLastPage ? "Start writing" : "Continue") {
                    if isLastPage {
                        onFinish()
                    } else {
                        withAnimation(.smooth) { index += 1 }
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            }
            .padding(Spacing.xl)
        }
        .overlay(alignment: .topTrailing) {
            if !isLastPage {
                Button("Skip", action: onFinish)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(Spacing.l)
            }
        }
    }

    private var isLastPage: Bool { index == pages.count - 1 }

    private func pageView(_ page: Page) -> some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            Image(systemName: page.symbol)
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(Color.accentColor)
                .symbolEffect(.bounce, value: index)
            VStack(spacing: Spacing.m) {
                Text(page.title)
                    .font(.system(.largeTitle, design: .serif).weight(.semibold))
                    .multilineTextAlignment(.center)
                Text(page.body)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
    }

    private struct Page {
        let symbol: String
        let title: String
        let body: String
    }
}

private struct PageDots: View {
    let count: Int
    let index: Int

    var body: some View {
        HStack(spacing: Spacing.s) {
            ForEach(0..<count, id: \.self) { dot in
                Circle()
                    .fill(dot == index ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 7, height: 7)
            }
        }
        .animation(.smooth, value: index)
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
