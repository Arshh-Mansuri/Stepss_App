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

    /// Subtract `points` from the balance. Throws `WalletError.insufficientFunds`
    /// if the user doesn't have enough — caller should disable the spend CTA
    /// before calling, but the throw is the safety net for race conditions.
    func debit(points: Int) throws {
        guard points > 0 else { return }
        guard balance >= points else { throw WalletError.insufficientFunds }
        balance -= points
        defaults.set(balance, forKey: balanceKey)
    }

    /// Set the balance back to zero. Used by the dev "Reset balance" row.
    /// Also clears LedgerStore so the History tab and balance stay in sync —
    /// otherwise you'd see "balance 0" with leftover earn rows from yesterday.
    func reset() {
        balance = 0
        defaults.set(0, forKey: balanceKey)
        LedgerStore.shared.reset()
    }
}

enum WalletError: Error, LocalizedError {
    case insufficientFunds

    var errorDescription: String? {
        switch self {
        case .insufficientFunds: return "Not enough points."
        }
    }
}
