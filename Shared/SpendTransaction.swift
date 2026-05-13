import Foundation
import SwiftData

@Model
final class SpendTransaction {
    @Attribute(.unique) var id: UUID
    var occurredAt: Date
    var pointsSpent: Int
    var unlockMinutes: Int
    var gatedAppRuleId: UUID
    var dayBucket: String

    init(
        id: UUID = UUID(),
        occurredAt: Date = .now,
        pointsSpent: Int,
        unlockMinutes: Int,
        gatedAppRuleId: UUID,
        dayBucket: String
    ) {
        self.id = id
        self.occurredAt = occurredAt
        self.pointsSpent = pointsSpent
        self.unlockMinutes = unlockMinutes
        self.gatedAppRuleId = gatedAppRuleId
        self.dayBucket = dayBucket
    }
}
