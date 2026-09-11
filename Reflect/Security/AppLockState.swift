import LocalAuthentication
import Observation

/// Which on-device authentication is available, so Settings and the lock
/// screen can name it correctly instead of assuming "Face ID".
enum BiometryKind: Equatable {
    case faceID
    case touchID
    case passcodeOnly
    case unavailable

    var label: String {
        switch self {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .passcodeOnly: return "Passcode"
        case .unavailable: return "Passcode"
        }
    }

    var symbolName: String {
        switch self {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .passcodeOnly, .unavailable: return "lock"
        }
    }
}

/// Gates the app behind Face ID / Touch ID / passcode. Kept as one small,
/// testable-by-inspection type rather than spread across views: the lock
/// screen and Settings both just read `isUnlocked` / call `authenticate`.
@MainActor
@Observable
final class AppLockState {

    private(set) var isUnlocked = false
    private(set) var isAuthenticating = false
    private(set) var errorMessage: String?

    /// Whether this device can authenticate the owner at all (biometry or a
    /// passcode). If not, there's nothing to lock with, so the Settings
    /// toggle is disabled rather than promising a lock that can't happen.
    static func availableBiometry() -> BiometryKind {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return .unavailable
        }
        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        default: return .passcodeOnly
        }
    }

    /// Locks again — called when the app leaves the foreground.
    func lock() {
        isUnlocked = false
        errorMessage = nil
    }

    func authenticate(reason: String) async {
        guard !isAuthenticating else { return }
        errorMessage = nil
        isAuthenticating = true
        defer { isAuthenticating = false }

        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"

        var setupError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &setupError) else {
            // Nothing configured to authenticate with — don't hold the journal hostage.
            isUnlocked = true
            return
        }

        do {
            let success = try await context.evaluate(.deviceOwnerAuthentication, reason: reason)
            isUnlocked = success
        } catch {
            isUnlocked = false
            errorMessage = Self.message(for: error)
        }
    }

    private static func message(for error: Error) -> String? {
        guard let laError = error as? LAError else {
            return "Couldn't verify it's you. Try again."
        }
        switch laError.code {
        case .userCancel, .appCancel, .systemCancel, .userFallback:
            return nil // they backed out; no need to alarm them
        case .passcodeNotSet:
            return "Set a passcode on this device to use this."
        case .biometryNotEnrolled:
            return "Face ID / Touch ID isn't set up on this device."
        case .biometryLockout:
            return "Too many attempts. Enter your device passcode, then try again."
        default:
            return "Couldn't verify it's you. Try again."
        }
    }
}

private extension LAContext {
    /// Bridges the completion-handler API to `async`, on the caller's actor.
    func evaluate(_ policy: LAPolicy, reason: String) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            self.evaluatePolicy(policy, localizedReason: reason) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }
}
