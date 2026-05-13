import DeviceActivity
import FamilyControls
import ManagedSettings
import Foundation

class StepLockMonitorExtension: DeviceActivityMonitor {
    private nonisolated static let appGroupID = "group.uts.StepLock"
    private nonisolated static let selectionKey = "RestrictedAppSelection"

    nonisolated override init() {
        super.init()
    }

    nonisolated override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        ManagedSettingsStore().clearAllSettings()
    }

    nonisolated override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        reApplyShields()
    }

    private nonisolated func reApplyShields() {
        let defaults = UserDefaults(suiteName: Self.appGroupID) ?? .standard
        guard let data = defaults.data(forKey: Self.selectionKey),
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
