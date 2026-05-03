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
        // Note: authorizationStatus(for:) reflects WRITE permission only. Read access is
        // intentionally hidden by Apple — we'll know it's denied if step queries return empty.
        log.info("HK authorization request completed")
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

    /// Returns daily step counts for the last `daysBack` complete days (not including today).
    /// Returned dictionary is keyed by the start-of-day Date for each bucket. Days with no
    /// samples are still present in the result with a value of 0.
    func dailyStepHistory(daysBack: Int) async throws -> [Date: Int] {
        precondition(daysBack > 0, "daysBack must be positive")
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -daysBack, to: startOfToday) else {
            return [:]
        }

        var interval = DateComponents()
        interval.day = 1

        return try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: startOfToday, options: .strictStartDate)
            let query = HKStatisticsCollectionQuery(
                quantityType: HealthKitConfig.stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: startDate,
                intervalComponents: interval
            )

            query.initialResultsHandler = { _, results, error in
                if let nsError = error as NSError?,
                   nsError.domain == HKError.errorDomain,
                   nsError.code == HKError.errorNoData.rawValue {
                    continuation.resume(returning: [:])
                    return
                }
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let results else {
                    continuation.resume(returning: [:])
                    return
                }
                var output: [Date: Int] = [:]
                results.enumerateStatistics(from: startDate, to: startOfToday) { stats, _ in
                    let count = Int((stats.sumQuantity()?.doubleValue(for: .count()) ?? 0).rounded())
                    output[stats.startDate] = count
                }
                continuation.resume(returning: output)
            }

            store.execute(query)
        }
    }

    /// Returns the cumulative step count for the current local day (midnight → now).
    /// Returns 0 when the user has no step samples for today (a normal state on
    /// simulators or for users who haven't moved). Caller is responsible for
    /// triggering re-reads on relevant signals (foreground, observer callback, refresh).
    func todayStepCount() async throws -> Int {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        guard let stats = try await fetchStatistics(predicate: predicate) else { return 0 }
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
        let stats: HKStatistics?
        do {
            stats = try await fetchStatistics(predicate: predicate)
        } catch {
            log.error("HKStatisticsQuery failed: \(error.localizedDescription, privacy: .public)")
            return
        }

        let stepCount = stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0
        let delta = Int(stepCount.rounded())

        if delta > 0 {
            await EarningService.shared.record(stepDelta: delta, occurredAt: now)
        }
        setLastSyncDate(now)
    }

    /// Returns nil when HealthKit reports `errorNoData` — i.e., the predicate matches
    /// zero samples. Callers treat nil as "no steps in this range" rather than a failure.
    private func fetchStatistics(predicate: NSPredicate) async throws -> HKStatistics? {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: HealthKitConfig.stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let nsError = error as NSError?,
                   nsError.domain == HKError.errorDomain,
                   nsError.code == HKError.errorNoData.rawValue {
                    continuation.resume(returning: nil)
                    return
                }
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: statistics)
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
