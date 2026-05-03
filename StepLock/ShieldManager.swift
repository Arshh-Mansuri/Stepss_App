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
    
    // Apply (or remove) the shield based on what's currently selected.
    // Apps and categories are applied independently — picking one app should
    // NOT shield every other app on the device.
    func applyShield() {
        let applications = selection.applicationTokens
        let categories = selection.categoryTokens

        // Apps: shield only the specific tokens the user picked.
        store.shield.applications = applications.isEmpty ? nil : applications

        // Categories: shield only the specific categories the user picked.
        // .all(except:) means "shield every category" — only use it if the
        // user actually selected the top-level "All Apps and Categories" row.
        store.shield.applicationCategories = categories.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(categories)
    }
}
