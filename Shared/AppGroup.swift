import Foundation

// nonisolated so non-MainActor callers (e.g. EarningService actor) can read
// the App Group container without hopping to the main actor.
nonisolated enum AppGroup {
    // The architecture spec calls for "group.com.steplock.shared". For now
    // the App Group capability is temporarily DISABLED in entitlements so
    // the project signs cleanly without a developer-portal registration.
    // Re-enable when (a) the App Group is registered on the team, and
    // (b) extension targets are introduced and need cross-process storage.
    static let identifier = "group.uts.StepLock"

    /// Returns nil when the App Group capability isn't enabled. Currently
    /// only used by the dormant ModelContainerFactory; SwiftData wiring is
    /// not active in v1.
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    /// Returns the App Group UserDefaults suite if available, otherwise the
    /// app's standard UserDefaults. While the App Group capability is off
    /// (no extensions yet) this transparently falls back, so all our stores
    /// (WalletStore, OnboardingState, UnlockStore, LedgerStore) keep working
    /// without needing changes.
    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}
