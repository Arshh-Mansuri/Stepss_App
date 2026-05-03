import Foundation
import HealthKit

enum HealthKitConfig {
    static let stepType = HKQuantityType(.stepCount)
    static let backgroundFrequency: HKUpdateFrequency = .hourly

    enum DefaultsKey {
        static let lastSyncDate = "healthkit.stepCount.lastSyncDate"
        static let stepsPerPoint = "earning.stepsPerPoint"
        static let dailyStepGoal = "earning.dailyStepGoal"
    }

    /// Steps required to earn one point. Range 1...10 per architecture doc §6.3.
    /// 1 = 1 step → 1 point (most generous, MVP default).
    /// 10 = 10 steps → 1 point (strictest).
    static let defaultStepsPerPoint = 1
    static let minStepsPerPoint = 1
    static let maxStepsPerPoint = 10

    static let defaultDailyStepGoal = 10_000
}
