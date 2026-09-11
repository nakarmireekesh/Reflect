import SwiftUI

/// Full-screen gate shown while the app is locked. Sits over the whole app,
/// not just one tab, so there's no path to content without unlocking.
struct LockView: View {
    var appLock: AppLockState

    private static let reason = "Unlock Reflect"

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image(systemName: "lock.fill")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Color.brand)

            VStack(spacing: Spacing.s) {
                Text("Reflect is locked")
                    .font(.system(.title2, design: .serif).weight(.semibold))
                Text("Your journal stays private.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let message = appLock.errorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            Button {
                Task { await appLock.authenticate(reason: Self.reason) }
            } label: {
                Text(appLock.isAuthenticating ? "Verifying…" : "Unlock")
                    .frame(maxWidth: 220)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.brand)
            .disabled(appLock.isAuthenticating)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .task {
            if !appLock.isUnlocked {
                await appLock.authenticate(reason: Self.reason)
            }
        }
    }
}
