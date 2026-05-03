import Foundation
import HealthKit

enum HealthKitConfig {
    static let stepType = HKQuantityType(.stepCount)
    static let backgroundFrequency: HKUpdateFrequency = .hourly

    enum DefaultsKey {
        static let lastSyncDate = "healthkit.stepCount.lastSyncDate"
        static let pointsPerStep = "earning.pointsPerStep"
        static let dailyStepGoal = "earning.dailyStepGoal"
    }

    static let defaultPointsPerStep = 1
    static let defaultDailyStepGoal = 10_000
}
