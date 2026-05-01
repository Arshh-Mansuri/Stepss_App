import Foundation
import SwiftData

@Model
final class EarnTransaction {
    @Attribute(.unique) var id: UUID
    var occurredAt: Date
    var steps: Int
    var pointsEarned: Int
    var rateApplied: Int
    var dayBucket: String
    var source: String

    init(
        id: UUID = UUID(),
        occurredAt: Date = .now,
        steps: Int,
        pointsEarned: Int,
        rateApplied: Int,
        dayBucket: String,
        source: String
    ) {
        self.id = id
        self.occurredAt = occurredAt
        self.steps = steps
        self.pointsEarned = pointsEarned
        self.rateApplied = rateApplied
        self.dayBucket = dayBucket
        self.source = source
    }
}
