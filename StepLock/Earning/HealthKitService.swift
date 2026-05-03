import Foundation
import HealthKit
import os

enum HealthKitServiceError: Error {
    case notAvailableOnDevice
    case authorizationDenied
}

actor HealthKitService {
    static let shared = HealthKitService()

    private let log = Logger(subsystem: "com.steplock", category: "healthkit")
    private let store = HKHealthStore()
    private let defaults: UserDefaults
    private var observerQuery: HKObserverQuery?

    private init(defaults: UserDefaults = AppGroup.sharedDefaults) {
        self.defaults = defaults
    }

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitServiceError.notAvailableOnDevice
        }
        try await store.requestAuthorization(toShare: [], read: [HealthKitConfig.stepType])
        // HealthKit never reports "denied" for read access by design — the only signal is
        // queries returning zero data. We log status here for visibility.
        let status = store.authorizationStatus(for: HealthKitConfig.stepType)
        log.info("HK auth status after request: \(status.rawValue, privacy: .public)")
    }

    func start() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitServiceError.notAvailableOnDevice
        }

        try await store.enableBackgroundDelivery(
            for: HealthKitConfig.stepType,
            frequency: HealthKitConfig.backgroundFrequency
        )

        let query = HKObserverQuery(sampleType: HealthKitConfig.stepType, predicate: nil) { [weak self] _, completion, error in
            defer { completion() }
            if let error {
                Task { await self?.logQueryError(error) }
                return
            }
            Task { await self?.handleStepUpdate() }
        }

        store.execute(query)
        observerQuery = query
        log.info("HKObserverQuery registered for stepCount")
    }

    private func logQueryError(_ error: Error) {
        log.error("HKObserverQuery error: \(error.localizedDescription, privacy: .public)")
    }

    /// Returns the cumulative step count for the current local day (midnight → now).
    /// Caller is responsible for triggering re-reads on relevant signals
    /// (foreground, observer-query callback, manual refresh).
    func todayStepCount() async throws -> Int {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        let stats = try await fetchStatistics(predicate: predicate)
        let count = stats.sumQuantity()?.doubleValue(for: .count()) ?? 0
        return Int(count.rounded())
    }

    private func handleStepUpdate() async {
        let now = Date()
        let anchor = lastSyncDate() ?? Calendar.current.startOfDay(for: now)

        guard anchor < now else {
            log.debug("Anchor is in the future; skipping update")
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: anchor, end: now, options: .strictStartDate)
        let stats: HKStatistics
        do {
            stats = try await fetchStatistics(predicate: predicate)
        } catch {
            log.error("HKStatisticsQuery failed: \(error.localizedDescription, privacy: .public)")
            return
        }

        let stepCount = stats.sumQuantity()?.doubleValue(for: .count()) ?? 0
        let delta = Int(stepCount.rounded())

        if delta > 0 {
            await EarningService.shared.record(stepDelta: delta, occurredAt: now)
        }
        setLastSyncDate(now)
    }

    private func fetchStatistics(predicate: NSPredicate) async throws -> HKStatistics {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: HealthKitConfig.stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let statistics {
                    continuation.resume(returning: statistics)
                } else {
                    continuation.resume(throwing: HealthKitServiceError.notAvailableOnDevice)
                }
            }
            store.execute(query)
        }
    }

    private func lastSyncDate() -> Date? {
        defaults.object(forKey: HealthKitConfig.DefaultsKey.lastSyncDate) as? Date
    }

    private func setLastSyncDate(_ date: Date) {
        defaults.set(date, forKey: HealthKitConfig.DefaultsKey.lastSyncDate)
    }
}
