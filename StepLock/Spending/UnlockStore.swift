import Foundation
import Observation
import ManagedSettings

/// Observable store for the user's currently-active unlock window (if any).
/// Persists the session to App Group UserDefaults so it survives launches.
///
/// MVP scope (per Arsh, deferring Aditya's spec):
/// - Single active session (architecture says one app per spend; we extend
///   that to "one at a time" to keep the demo simple).
/// - Expiry is best-effort: checked on app foreground / scenePhase. The
///   real DeviceActivityMonitor extension will eventually replace this.
@MainActor
@Observable
final class UnlockStore {
    static let shared = UnlockStore()

    private(set) var activeSession: UnlockSession?

    private let defaults: UserDefaults
    private let storageKey = "unlock.activeSession"

    init(defaults: UserDefaults = AppGroup.sharedDefaults) {
        self.defaults = defaults
        self.activeSession = Self.load(from: defaults, key: storageKey)
    }

    /// Start a new unlock window. Replaces any existing session (single-active rule).
    func start(_ session: UnlockSession) {
        activeSession = session
        persist()
        ShieldManager.shared.applyShield()
    }

    /// Stop the current unlock immediately (used on user dismiss or expiry).
    func clear() {
        activeSession = nil
        persist()
        ShieldManager.shared.applyShield()
    }

    /// If the active session has expired, drop it and re-apply the full shield.
    /// Safe to call frequently (foreground, scenePhase, timer).
    func checkExpiry() {
        guard let session = activeSession, !session.isActive else { return }
        // Ah, guard backwards — fix:
    }

    /// Returns true if an unlock just expired and was cleared.
    @discardableResult
    func reapIfExpired() -> Bool {
        guard let session = activeSession, session.expiresAt <= Date() else { return false }
        activeSession = nil
        persist()
        ShieldManager.shared.applyShield()
        return true
    }

    /// Token of the currently-unlocked app (if any). ShieldManager uses this
    /// to exempt that app from the shield via .except.
    var activeApplicationToken: ApplicationToken? {
        activeSession?.token
    }

    // MARK: - Persistence

    private func persist() {
        if let session = activeSession,
           let data = try? JSONEncoder().encode(session) {
            defaults.set(data, forKey: storageKey)
        } else {
            defaults.removeObject(forKey: storageKey)
        }
    }

    private static func load(from defaults: UserDefaults, key: String) -> UnlockSession? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(UnlockSession.self, from: data)
    }
}
