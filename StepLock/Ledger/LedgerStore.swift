import Foundation
import Observation

/// Append-only history of earn and spend events. Persists Codable entries to
/// App Group UserDefaults as JSON, capped FIFO at `maxEntries` so storage
/// can't bloat unboundedly.
///
/// MVP storage choice: UserDefaults JSON, mirroring WalletStore / UnlockStore.
/// Will migrate to SwiftData (then GRDB per spec) when the team-wide storage
/// decision lands. The recordEarn / recordSpend / reset API is narrow on
/// purpose so the swap is a single-file change.
@MainActor
@Observable
final class LedgerStore {
    static let shared = LedgerStore()

    /// Newest first. Capped at `maxEntries` (FIFO drop oldest on append).
    private(set) var entries: [LedgerEntry]

    /// FIFO cap. ~500 entries comfortably covers many weeks of HK callbacks.
    static let maxEntries = 500

    private let defaults: UserDefaults
    private let storageKey = "ledger.entries"

    init(defaults: UserDefaults = AppGroup.sharedDefaults) {
        self.defaults = defaults
        self.entries = Self.load(from: defaults, key: storageKey)
    }

    func recordEarn(stepDelta: Int, pointsEarned: Int, stepsPerPoint: Int, occurredAt: Date) {
        let payload = LedgerEntry.EarnPayload(
            id: UUID(),
            occurredAt: occurredAt,
            stepDelta: stepDelta,
            pointsEarned: pointsEarned,
            stepsPerPoint: stepsPerPoint
        )
        append(.earn(payload))
    }

    func recordSpend(session: UnlockSession) {
        let payload = LedgerEntry.SpendPayload(
            id: session.id,
            occurredAt: session.startsAt,
            pointsSpent: session.pointsSpent,
            durationMinutes: session.durationMinutes,
            tokenData: session.tokenData
        )
        append(.spend(payload))
    }

    func reset() {
        entries = []
        persist()
    }

    // MARK: - Internals

    private func append(_ entry: LedgerEntry) {
        entries.insert(entry, at: 0)
        if entries.count > Self.maxEntries {
            entries.removeLast(entries.count - Self.maxEntries)
        }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: storageKey)
        }
    }

    private static func load(from defaults: UserDefaults, key: String) -> [LedgerEntry] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([LedgerEntry].self, from: data)) ?? []
    }
}
