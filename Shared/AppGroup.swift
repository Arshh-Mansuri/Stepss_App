import Foundation

// nonisolated so non-MainActor callers (e.g. EarningService actor) can read
// the App Group container without hopping to the main actor.
nonisolated enum AppGroup {
    // Matches the value provisioned in StepLock.entitlements / StepLockShield.entitlements.
    // Spec calls for "group.com.steplock.shared" but that string isn't registered
    // to this team's developer portal — using the original "group.uts.StepLock"
    // which is provisioned. We can rename to the spec value once the App Group
    // is registered with Apple (paid account + portal entry).
    static let identifier = "group.uts.StepLock"

    static var containerURL: URL {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) else {
            fatalError("App Group container unavailable — check entitlements for \(identifier)")
        }
        return url
    }

    static var sharedDefaults: UserDefaults {
        guard let defaults = UserDefaults(suiteName: identifier) else {
            fatalError("UserDefaults suite unavailable for App Group \(identifier)")
        }
        return defaults
    }
}
