//
//  StepLockApp.swift
//  StepLock
//
//  Created by JJ on 29/4/2026.
//

import SwiftUI
import os

@main
struct StepLockApp: App {
    private let log = Logger(subsystem: "com.steplock", category: "app")

    init() {
        
        // Initialize database FIRST (critical)
        _ = DatabaseManager.shared
        // If onboarding is already done from a previous launch, restart the
        // observer query so step deltas keep flowing on app boot. First-run
        // permission requests happen on the Permissions screen instead.
        let alreadyOnboarded = AppGroup.sharedDefaults.bool(forKey: OnboardingDefaultsKey.hasCompleted)
        guard alreadyOnboarded else { return }

        Task {
            do {
                try await HealthKitService.shared.start()
            } catch {
                Logger(subsystem: "com.steplock", category: "app")
                    .warning("HealthKit restart failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
