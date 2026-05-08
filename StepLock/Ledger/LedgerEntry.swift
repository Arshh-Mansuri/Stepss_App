import Foundation

/// One row in the user's transaction history. Two cases for the two real
/// flows we have today (earn from steps, spend on unlocks). Refund rows
/// will be added once Aditya's two-phase commit lands.
enum LedgerEntry: Codable, Identifiable, Equatable {
    case earn(EarnPayload)
    case spend(SpendPayload)
    case refund(RefundPayload)

    var id: UUID {
        switch self {
        case .earn(let p): return p.id
        case .spend(let p): return p.id
        case .refund(let p): return p.id
        }
    }

    var occurredAt: Date {
        switch self {
        case .earn(let p):  return p.occurredAt
        case .spend(let p): return p.occurredAt
        case .refund(let p): return p.occurredAt
        }
    }

    /// Positive for earn/refund, negative for spend. Used by the "This week" summary.
    var pointsDelta: Int {
        switch self {
        case .earn(let p):  return p.pointsEarned
        case .spend(let p): return -p.pointsSpent
        case .refund(let p): return p.pointsRefunded
        }
    }

    struct EarnPayload: Codable, Equatable {
        let id: UUID
        let occurredAt: Date
        let stepDelta: Int
        let pointsEarned: Int
        let stepsPerPoint: Int
    }
    
    struct RefundPayload: Codable, Equatable {
        let id: UUID           // matches the original SpendPayload.id
        let occurredAt: Date
        let pointsRefunded: Int
        let reason: String
    }

    struct SpendPayload: Codable, Equatable {
        let id: UUID
        let occurredAt: Date
        let pointsSpent: Int
        let durationMinutes: Int
        /// Discriminator for tokenData. Older entries written before this field
        /// existed default to .application via the custom decoder below.
        let kind: UnlockTargetKind
        /// Encoded ApplicationToken or ActivityCategoryToken (PropertyListEncoder,
        /// same encoding as UnlockSession). HistoryView decodes this for
        /// Label(token:) rendering.
        let tokenData: Data

        enum CodingKeys: String, CodingKey {
            case id, occurredAt, pointsSpent, durationMinutes, kind, tokenData
        }

        init(id: UUID, occurredAt: Date, pointsSpent: Int, durationMinutes: Int, kind: UnlockTargetKind, tokenData: Data) {
            self.id = id
            self.occurredAt = occurredAt
            self.pointsSpent = pointsSpent
            self.durationMinutes = durationMinutes
            self.kind = kind
            self.tokenData = tokenData
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decode(UUID.self, forKey: .id)
            self.occurredAt = try container.decode(Date.self, forKey: .occurredAt)
            self.pointsSpent = try container.decode(Int.self, forKey: .pointsSpent)
            self.durationMinutes = try container.decode(Int.self, forKey: .durationMinutes)
            self.tokenData = try container.decode(Data.self, forKey: .tokenData)
            // Backward-compat: older spend entries had no `kind` field — treat as application.
            self.kind = try container.decodeIfPresent(UnlockTargetKind.self, forKey: .kind) ?? .application
        }
    }
}
