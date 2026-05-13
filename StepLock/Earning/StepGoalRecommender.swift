import Foundation

enum StepGoalRecommender {
    static let minimum = 3_000
    static let maximum = 25_000
    static let increment = 500

    /// Pick a sensible daily step goal based on the user's recent history.
    /// Logic: average of non-zero days, +15% to encourage growth, rounded
    /// to the nearest 500, clamped to [minimum, maximum]. Falls back to the
    /// supplied default when there's no usable history.
    static func recommend(from history: [Int], default fallback: Int = HealthKitConfig.defaultDailyStepGoal) -> Int {
        let nonZero = history.filter { $0 > 0 }
        guard !nonZero.isEmpty else { return clamp(round(fallback)) }

        let avg = Double(nonZero.reduce(0, +)) / Double(nonZero.count)
        let suggested = avg * 1.15
        return clamp(round(Int(suggested.rounded())))
    }

    static func clamp(_ value: Int) -> Int {
        max(minimum, min(maximum, value))
    }

    static func round(_ value: Int) -> Int {
        let stepped = (Double(value) / Double(increment)).rounded() * Double(increment)
        return Int(stepped)
    }
}
