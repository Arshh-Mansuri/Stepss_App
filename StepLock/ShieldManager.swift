import Foundation
import FamilyControls
import ManagedSettings
import Observation // 

@Observable //
class ShieldManager {
    // A single instance that everyone shares (Singleton pattern)
    static let shared = ShieldManager()
    
    // An object provided by Apple to change system-level app restrictions
    private let store = ManagedSettingsStore()
    
    // Holds the apps the user has selected.
    // When this changes, we call applyShield()
    var selection = FamilyActivitySelection() {
        didSet {
            applyShield()
        }
    }
    
    // Apply (or remove) the shield based on what's currently selected, while
    // respecting any in-progress UnlockStore session (the unlocked app is
    // temporarily exempted via .except).
    func applyShield() {
        let applications = selection.applicationTokens
        let categories = selection.categoryTokens

        let exemptions: Set<ApplicationToken> = {
            guard let token = UnlockStore.shared.activeApplicationToken else { return [] }
            return [token]
        }()

        let shieldedApps = applications.subtracting(exemptions)
        store.shield.applications = shieldedApps.isEmpty ? nil : shieldedApps

        store.shield.applicationCategories = categories.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(categories, except: exemptions)
    }
}
