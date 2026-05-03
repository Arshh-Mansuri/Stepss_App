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

        // App-level exemption: drop one app token from the shielded set.
        let appExemptions: Set<ApplicationToken> = {
            guard let token = UnlockStore.shared.activeApplicationToken else { return [] }
            return [token]
        }()

        // Category-level exemption: drop the unlocked category from the shielded
        // set entirely. ManagedSettings doesn't let us partially exempt a
        // category, so a category unlock means "the whole category is open".
        let categoryExemptions: Set<ActivityCategoryToken> = {
            guard let token = UnlockStore.shared.activeCategoryToken else { return [] }
            return [token]
        }()

        let shieldedApps = applications.subtracting(appExemptions)
        store.shield.applications = shieldedApps.isEmpty ? nil : shieldedApps

        let shieldedCategories = categories.subtracting(categoryExemptions)
        store.shield.applicationCategories = shieldedCategories.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(shieldedCategories, except: appExemptions)
    }
}
