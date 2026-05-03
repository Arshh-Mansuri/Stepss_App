import Foundation
import ManagedSettings

/// Discriminator for what kind of token an unlock targets — apps and
/// categories are both pickable in the FamilyActivityPicker, and we treat
/// either as a valid spend target.
enum UnlockTargetKind: String, Codable {
    case application
    case category
}

/// One active "unlock window" — user spent N points to use a specific app
/// (or category) for D minutes. Persists across launches via UnlockStore
/// (encoded to App Group UserDefaults).
struct UnlockSession: Codable, Equatable {
    let id: UUID
    let kind: UnlockTargetKind
    let tokenData: Data         // Codable-encoded ApplicationToken or ActivityCategoryToken
    let startsAt: Date
    let expiresAt: Date
    let pointsSpent: Int
    let durationMinutes: Int

    var applicationToken: ApplicationToken? {
        guard kind == .application else { return nil }
        return try? PropertyListDecoder().decode(ApplicationToken.self, from: tokenData)
    }

    var categoryToken: ActivityCategoryToken? {
        guard kind == .category else { return nil }
        return try? PropertyListDecoder().decode(ActivityCategoryToken.self, from: tokenData)
    }

    var isActive: Bool {
        Date() < expiresAt
    }

    var remainingSeconds: Int {
        max(0, Int(expiresAt.timeIntervalSinceNow))
    }

    static func make(applicationToken: ApplicationToken, pointsSpent: Int, durationMinutes: Int) throws -> UnlockSession {
        let data = try PropertyListEncoder().encode(applicationToken)
        let now = Date()
        return UnlockSession(
            id: UUID(),
            kind: .application,
            tokenData: data,
            startsAt: now,
            expiresAt: now.addingTimeInterval(TimeInterval(durationMinutes * 60)),
            pointsSpent: pointsSpent,
            durationMinutes: durationMinutes
        )
    }

    static func make(categoryToken: ActivityCategoryToken, pointsSpent: Int, durationMinutes: Int) throws -> UnlockSession {
        let data = try PropertyListEncoder().encode(categoryToken)
        let now = Date()
        return UnlockSession(
            id: UUID(),
            kind: .category,
            tokenData: data,
            startsAt: now,
            expiresAt: now.addingTimeInterval(TimeInterval(durationMinutes * 60)),
            pointsSpent: pointsSpent,
            durationMinutes: durationMinutes
        )
    }
}
