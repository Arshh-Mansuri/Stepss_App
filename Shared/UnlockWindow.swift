import Foundation
import SwiftData

@Model
final class UnlockWindow {
    @Attribute(.unique) var id: UUID
    var gatedAppRuleId: UUID
    var startsAt: Date
    var expiresAt: Date
    var consumedSpendId: UUID

    init(
        id: UUID = UUID(),
        gatedAppRuleId: UUID,
        startsAt: Date,
        expiresAt: Date,
        consumedSpendId: UUID
    ) {
        self.id = id
        self.gatedAppRuleId = gatedAppRuleId
        self.startsAt = startsAt
        self.expiresAt = expiresAt
        self.consumedSpendId = consumedSpendId
    }

    var isActive: Bool {
        Date.now < expiresAt
    }
}
