import Foundation
import SwiftData

@Model
final class AppSettings {
    var stepsPerPoint: Int
    var dailyEarnCapPoints: Int?
    var dailySpendCapPoints: Int?
    var milestoneThresholds: [Int]
    var updatedAt: Date

    init(
        stepsPerPoint: Int = 100,
        dailyEarnCapPoints: Int? = nil,
        dailySpendCapPoints: Int? = nil,
        milestoneThresholds: [Int] = [5_000, 10_000, 15_000],
        updatedAt: Date = .now
    ) {
        self.stepsPerPoint = stepsPerPoint
        self.dailyEarnCapPoints = dailyEarnCapPoints
        self.dailySpendCapPoints = dailySpendCapPoints
        self.milestoneThresholds = milestoneThresholds
        self.updatedAt = updatedAt
    }
}
