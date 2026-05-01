import Foundation

enum AppGroup {
    // Matches the value provisioned in StepLock.entitlements / StepLockShield.entitlements.
    // Will become "group.com.stridetime.shared" on the StrideTime rename.
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
