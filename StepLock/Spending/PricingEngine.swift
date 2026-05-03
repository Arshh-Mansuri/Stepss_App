import Foundation

/// Pricing tiers for spending points → unlock duration. Defaults match
/// architecture doc §8.2. Stored in App Group UserDefaults so they can
/// be tweaked without an app release; falls back to hardcoded values.
enum PricingEngine {
    struct Tier: Identifiable, Hashable {
        let id: String
        let durationMinutes: Int
        let pointsCost: Int
        let title: String
        let hint: String
    }

    static let tiers: [Tier] = [
        Tier(id: "15m", durationMinutes: 15, pointsCost: 500,  title: "15 min", hint: "Quick check"),
        Tier(id: "30m", durationMinutes: 30, pointsCost: 900,  title: "30 min", hint: "Most popular"),
        Tier(id: "60m", durationMinutes: 60, pointsCost: 1_600, title: "60 min", hint: "Best value"),
    ]

    static let minimumDurationMinutes = 15
}
