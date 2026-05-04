//
//  UnlockScheduler.swift
//  StepLock
//
//  Created by Aditya Sanap on 4/5/2026.
//


import Foundation
import DeviceActivity

actor UnlockScheduler {
    static let shared = UnlockScheduler()

    private let center = DeviceActivityCenter()

    // Activity name shared with the future monitor extension via App Group.
    static let activityName = DeviceActivityName("com.steplock.unlock")

    func schedule(session: UnlockSession) async throws {
        let calendar = Calendar.current
        let schedule = DeviceActivitySchedule(
            intervalStart: calendar.dateComponents([.hour, .minute, .second], from: session.startsAt),
            intervalEnd: calendar.dateComponents([.hour, .minute, .second], from: session.expiresAt),
            repeats: false
        )
        do {
            try center.startMonitoring(Self.activityName, during: schedule)
        } catch {
            // Phase 2 failure — scheduling denied by iOS, trigger refund.
            await SpendingLedger.shared.refund(session: session, reason: "scheduling_failed")
            throw UnlockSchedulerError.schedulingFailed(underlying: error)
        }
    }

    func cancel() {
        center.stopMonitoring([Self.activityName])
    }
}

enum UnlockSchedulerError: Error, LocalizedError {
    case schedulingFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .schedulingFailed(let e):
            return "Could not schedule unlock: \(e.localizedDescription)"
        }
    }
}
