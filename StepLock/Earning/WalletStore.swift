import Foundation
import Observation

/// Single in-memory + persisted source of truth for the user's point balance.
/// MainActor-isolated so SwiftUI views can read it directly.
///
/// MVP storage: App Group UserDefaults. Will migrate to GRDB (per architecture
/// doc §3) once the team-wide storage decision lands and Aditya's
/// SpendingLedger.earn() is published. The credit/reset/balance API is
/// intentionally narrow so the swap is a one-file change.
@MainActor
@Observable
final class WalletStore {
    static let shared = WalletStore()

    private(set) var balance: Int

    private let defaults: UserDefaults
    private let balanceKey = "wallet.balance"

    init(defaults: UserDefaults = AppGroup.sharedDefaults) {
        self.defaults = defaults
        self.balance = defaults.integer(forKey: balanceKey)
    }

    /// Add `points` to the balance and persist. No-op for non-positive values.
    func credit(points: Int) {
        guard points > 0 else { return }
        balance += points
        defaults.set(balance, forKey: balanceKey)
    }

    /// Set the balance back to zero. Used by the dev "Reset balance" row.
    func reset() {
        balance = 0
        defaults.set(0, forKey: balanceKey)
    }
}
