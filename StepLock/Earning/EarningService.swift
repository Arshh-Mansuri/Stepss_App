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

        let storedRate = defaults.object(forKey: HealthKitConfig.DefaultsKey.stepsPerPoint) as? Int
            ?? HealthKitConfig.defaultStepsPerPoint
        let stepsPerPoint = max(HealthKitConfig.minStepsPerPoint,
                                min(HealthKitConfig.maxStepsPerPoint, storedRate))
        let points = stepDelta / stepsPerPoint  // integer division; floor

        guard points > 0 else {
            log.debug("Skipped credit: \(stepDelta) steps below \(stepsPerPoint) steps-per-point threshold")
            return
        }

        log.info("Earned \(points, privacy: .public) pts from \(stepDelta, privacy: .public) steps (rate 1 pt / \(stepsPerPoint, privacy: .public) steps) at \(occurredAt, privacy: .public)")

        await SpendingLedger.shared.earn(
            points: points,
            stepDelta: stepDelta,
            stepsPerPoint: stepsPerPoint,
            occurredAt: occurredAt
        )
    }
}
