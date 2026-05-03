import Foundation

/// One row in the user's transaction history. Two cases for the two real
/// flows we have today (earn from steps, spend on unlocks). Refund rows
/// will be added once Aditya's two-phase commit lands.
enum LedgerEntry: Codable, Identifiable, Equatable {
    case earn(EarnPayload)
    case spend(SpendPayload)

    var id: UUID {
        switch self {
        case .earn(let p):  return p.id
        case .spend(let p): return p.id
        }
    }

    var occurredAt: Date {
        switch self {
        case .earn(let p):  return p.occurredAt
        case .spend(let p): return p.occurredAt
        }
    }

    /// Positive for earn, negative for spend. Used by the "This week" summary.
    var pointsDelta: Int {
        switch self {
        case .earn(let p):  return p.pointsEarned
        case .spend(let p): return -p.pointsSpent
        }
    }

    struct EarnPayload: Codable, Equatable {
        let id: UUID
        let occurredAt: Date
        let stepDelta: Int
        let pointsEarned: Int
        let stepsPerPoint: Int
    }

    struct SpendPayload: Codable, Equatable {
        let id: UUID
        let occurredAt: Date
        let pointsSpent: Int
        let durationMinutes: Int
        /// Encoded ApplicationToken (PropertyListEncoder, same encoding as
        /// UnlockSession). HistoryView decodes this for Label(token:) rendering.
        let tokenData: Data
    }
}
