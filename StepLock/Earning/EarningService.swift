import Foundation
import os

actor EarningService {
    static let shared = EarningService()

    private let log = Logger(subsystem: "com.steplock", category: "earning")
    private let defaults: UserDefaults

    private init(defaults: UserDefaults = AppGroup.sharedDefaults) {
        self.defaults = defaults
    }

    func record(stepDelta: Int, occurredAt: Date) async {
        guard stepDelta > 0 else { return }

        let pointsPerStep = defaults.object(forKey: HealthKitConfig.DefaultsKey.pointsPerStep) as? Int
            ?? HealthKitConfig.defaultPointsPerStep
        let points = stepDelta * pointsPerStep

        log.info("Earned \(points, privacy: .public) pts from \(stepDelta, privacy: .public) steps at \(occurredAt, privacy: .public)")

        // TODO(arsh-followup): swap WalletStore.credit for Aditya's
        // SpendingLedger.earn(points:metadata:) once it's published.
        await MainActor.run {
            WalletStore.shared.credit(points: points)
        }
    }
}
