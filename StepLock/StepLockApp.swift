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
        Task { @Sendable in
            do {
                try await HealthKitService.shared.requestAuthorization()
                try await HealthKitService.shared.start()
            } catch {
                Logger(subsystem: "com.steplock", category: "app")
                    .warning("HealthKit boot failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
