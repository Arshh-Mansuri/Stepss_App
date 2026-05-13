//
//  SpendingLedger.swift
//  StepLock
//
//  Created by Aditya Sanap on 4/5/2026.
//


import Foundation

actor SpendingLedger {
    static let shared = SpendingLedger()

    private let defaults: UserDefaults
    private let dailySpendKey = "spendingLedger.dailySpend"  // [String: Int] dayBucket → points

    private init(defaults: UserDefaults = AppGroup.sharedDefaults) {
        self.defaults = defaults
    }

    // MARK: - Public API

    func earn(points: Int, stepDelta: Int, stepsPerPoint: Int, occurredAt: Date = .now) async {
        guard points > 0 else { return }
        await MainActor.run {
            WalletStore.shared.credit(points: points)
            LedgerStore.shared.recordEarn(
                stepDelta: stepDelta,
                pointsEarned: points,
                stepsPerPoint: stepsPerPoint,
                occurredAt: occurredAt
            )
        }
    }

    func spend(session: UnlockSession) async throws {
        let currentBalance = await MainActor.run { WalletStore.shared.balance }

        guard currentBalance >= session.pointsSpent else {
            throw SpendingLedgerError.insufficientFunds
        }

        try checkDailyCap(spending: session.pointsSpent)

        try await MainActor.run {
            try WalletStore.shared.debit(points: session.pointsSpent)
            LedgerStore.shared.recordSpend(session: session)
            UnlockStore.shared.start(session)
        }

        trackDailySpend(points: session.pointsSpent)
    }

    func refund(session: UnlockSession, reason: String = "scheduling_failed") async {
        await MainActor.run {
            WalletStore.shared.credit(points: session.pointsSpent)
            LedgerStore.shared.recordRefund(
                sessionId: session.id,
                points: session.pointsSpent,
                reason: reason
            )
        }
        untrackDailySpend(points: session.pointsSpent)
    }

    // MARK: - Daily cap

    private func checkDailyCap(spending points: Int) throws {
        guard let cap = defaults.object(forKey: "earning.dailySpendCapPoints") as? Int else { return }
        let todayKey = DayBucket.key()
        let dict = defaults.dictionary(forKey: dailySpendKey) as? [String: Int] ?? [:]
        let alreadySpent = dict[todayKey] ?? 0
        if alreadySpent + points > cap {
            throw SpendingLedgerError.dailyCapExceeded(cap: cap, spent: alreadySpent)
        }
    }

    private func trackDailySpend(points: Int) {
        var dict = defaults.dictionary(forKey: dailySpendKey) as? [String: Int] ?? [:]
        let key = DayBucket.key()
        dict[key] = (dict[key] ?? 0) + points
        defaults.set(dict, forKey: dailySpendKey)
    }

    private func untrackDailySpend(points: Int) {
        var dict = defaults.dictionary(forKey: dailySpendKey) as? [String: Int] ?? [:]
        let key = DayBucket.key()
        dict[key] = max(0, (dict[key] ?? 0) - points)
        defaults.set(dict, forKey: dailySpendKey)
    }
}

enum SpendingLedgerError: Error, LocalizedError {
    case insufficientFunds
    case dailyCapExceeded(cap: Int, spent: Int)

    var errorDescription: String? {
        switch self {
        case .insufficientFunds:
            return "Not enough points."
        case .dailyCapExceeded(let cap, let spent):
            return "Daily spend cap of \(cap) points reached (\(spent) already spent today)."
        }
    }
}
