import Foundation
import ManagedSettings

/// One active "unlock window" — user spent N points to use a specific app for D minutes.
/// Persists across launches via UnlockStore (encoded to App Group UserDefaults).
struct UnlockSession: Codable, Equatable {
    let id: UUID
    let tokenData: Data         // Codable-encoded ApplicationToken
    let startsAt: Date
    let expiresAt: Date
    let pointsSpent: Int
    let durationMinutes: Int

    var token: ApplicationToken? {
        try? PropertyListDecoder().decode(ApplicationToken.self, from: tokenData)
    }

    var isActive: Bool {
        Date() < expiresAt
    }

    var remainingSeconds: Int {
        max(0, Int(expiresAt.timeIntervalSinceNow))
    }

    static func make(token: ApplicationToken, pointsSpent: Int, durationMinutes: Int) throws -> UnlockSession {
        let data = try PropertyListEncoder().encode(token)
        let now = Date()
        return UnlockSession(
            id: UUID(),
            tokenData: data,
            startsAt: now,
            expiresAt: now.addingTimeInterval(TimeInterval(durationMinutes * 60)),
            pointsSpent: pointsSpent,
            durationMinutes: durationMinutes
        )
    }
}
