import Foundation

// nonisolated so non-MainActor callers (e.g. EarningService actor) can read
// the App Group container without hopping to the main actor.
nonisolated enum AppGroup {
    // Matches the value provisioned in StepLock.entitlements / StepLockShield.entitlements.
    // Per architecture doc §3 — shared by the main app and all extensions.
    static let identifier = "group.com.steplock.shared"

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
