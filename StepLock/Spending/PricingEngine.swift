import Foundation

/// PricingEngine defines the unlock economy for StepLock.
///
/// This is the single source of truth for:
/// - Available unlock durations
/// - Point costs per duration
/// - Validation for spend operations
///
/// Designed to be:
/// - UI-friendly (tiers for Spend screen)
/// - Ledger-safe (cost lookup for transactions)
/// - Future-proof (can later be backed by App Group config or remote rules)
enum PricingEngine {

    // MARK: - Tier Model

    struct Tier: Identifiable, Hashable {
        let id: String
        let durationMinutes: Int
        let pointsCost: Int
        let title: String
        let hint: String
    }

    // MARK: - Source of truth (economy rules)

    static let tiers: [Tier] = [
        Tier(
            id: "15m",
            durationMinutes: 15,
            pointsCost: 500,
            title: "15 min",
            hint: "Quick check"
        ),
        Tier(
            id: "30m",
            durationMinutes: 30,
            pointsCost: 900,
            title: "30 min",
            hint: "Most popular"
        ),
        Tier(
            id: "60m",
            durationMinutes: 60,
            pointsCost: 1600,
            title: "60 min",
            hint: "Best value"
        )
    ]

    // MARK: - Derived lookup tables (for fast access)

    private static let costMap: [Int: Int] = {
        Dictionary(uniqueKeysWithValues: tiers.map {
            ($0.durationMinutes, $0.pointsCost)
        })
    }()

    private static let tierMap: [Int: Tier] = {
        Dictionary(uniqueKeysWithValues: tiers.map {
            ($0.durationMinutes, $0)
        })
    }()

    // MARK: - Public API

    /// Returns cost for a given duration in minutes
    static func cost(for minutes: Int) -> Int? {
        costMap[minutes]
    }

    /// Returns full tier metadata for UI
    static func tier(for minutes: Int) -> Tier? {
        tierMap[minutes]
    }

    /// Returns all tiers sorted for UI display
    static func sortedTiers() -> [Tier] {
        tiers.sorted { $0.durationMinutes < $1.durationMinutes }
    }

    // MARK: - Validation

    static func isValidDuration(_ minutes: Int) -> Bool {
        costMap[minutes] != nil
    }

    static func canAfford(minutes: Int, balance: Int) -> Bool {
        guard let cost = cost(for: minutes) else { return false }
        return balance >= cost
    }

    // MARK: - Defaults / constants

    static let minimumDurationMinutes = 15
}
