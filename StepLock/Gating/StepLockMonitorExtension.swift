import DeviceActivity
import FamilyControls
import ManagedSettings
import Foundation

class StepLockMonitorExtension: DeviceActivityMonitor {
    nonisolated override init() {
        super.init()
    }

    nonisolated override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        let activityID = activity.rawValue.replacingOccurrences(of: "unlock-", with: "")
        print("JJ Monitor: Starting unlock for \(activityID)")

        ManagedSettingsStore().clearAllSettings()
    }

    nonisolated override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        print("JJ Monitor: Time is up. Re-applying shields.")
        reApplyShields()
    }

    private nonisolated func reApplyShields() {
        guard let data = AppGroup.sharedDefaults.data(forKey: "RestrictedAppSelection"),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else {
            return
        }

        let store = ManagedSettingsStore()
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
    }
}
