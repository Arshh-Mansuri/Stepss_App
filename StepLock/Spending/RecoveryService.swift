//
//  RecoveryService.swift
//  StepLock
//
//  Created by Aditya Sanap on 4/5/2026.
//


import Foundation

actor RecoveryService {
    static let shared = RecoveryService()

    func run() async {
        let reaped = await MainActor.run { UnlockStore.shared.reapIfExpired() }

        if reaped {
            // Session was expired — reapIfExpired() already cleared it and
            // re-applied the shield. Nothing more to do.
            return
        }

        await MainActor.run {
            if UnlockStore.shared.activeSession != nil {
                // Valid session survived the relaunch — re-enforce the shield
                // in case the app was killed before ShieldManager could apply it.
                ShieldManager.shared.applyShield()
            } else {
                // No session — cancel any stale DeviceActivity monitor left
                // running from a previous spend.
                Task { await UnlockScheduler.shared.cancel() }
            }
        }
    }
}
