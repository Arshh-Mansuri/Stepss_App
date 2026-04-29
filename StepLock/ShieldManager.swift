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
    
    // This is the function that actually turns the "lock" on or off
    func applyShield() {
        // Convert the selection into tokens the system understands
        let applications = selection.applicationTokens
        let categories = selection.categoryTokens
        
        // If the user hasn't selected anything, set everything to nil (Unlock)
        // If they have selected apps, apply the shield to those apps
        if applications.isEmpty && categories.isEmpty {
            store.shield.applications = nil
            store.shield.applicationCategories = nil
        } else {
            store.shield.applications = applications
            store.shield.applicationCategories = .all(except: [])
        }
    }
}
