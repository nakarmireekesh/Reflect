import Observation
import SwiftUI

/// Cycles a random subset of a prompt pool on a timer, so starter prompts
/// (Journal's empty state, Ask's suggestions) don't go stale for people who
/// keep the app open a while. Views call `start()` from a `.task` and read
/// `current`; mutating it inside `withAnimation` gives ForEach-driven views
/// a free cross-fade as long as each prompt has `.transition(.opacity)`.
@MainActor
@Observable
final class PromptRotator {
    private(set) var current: [String]
    private let pool: [String]
    private let count: Int
    private let interval: Duration

    init(pool: [String], count: Int, interval: Duration = .seconds(9)) {
        self.pool = pool
        self.count = min(count, pool.count)
        self.current = Array(pool.shuffled().prefix(self.count))
        self.interval = interval
    }

    func start() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: interval)
            guard !Task.isCancelled else { return }
            let next = Array(pool.shuffled().prefix(count))
            withAnimation(.easeInOut(duration: 0.4)) {
                current = next
            }
        }
    }
}
