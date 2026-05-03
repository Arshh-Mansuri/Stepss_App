import Foundation
import Observation

enum OnboardingDefaultsKey {
    static let hasCompleted = "onboarding.hasCompleted"
}

@Observable
final class OnboardingState {
    static let shared = OnboardingState()

    var currentStep: Int = 0
    var hasCompleted: Bool

    private let defaults: UserDefaults

    init(defaults: UserDefaults = AppGroup.sharedDefaults) {
        self.defaults = defaults
        self.hasCompleted = defaults.bool(forKey: OnboardingDefaultsKey.hasCompleted)
    }

    func advance() {
        currentStep = min(currentStep + 1, 3)
    }

    func goBack() {
        currentStep = max(currentStep - 1, 0)
    }

    func complete() {
        defaults.set(true, forKey: OnboardingDefaultsKey.hasCompleted)
        hasCompleted = true
    }

    // Debug helper — invoke from Settings later when we add a "Reset all data" row.
    func reset() {
        defaults.set(false, forKey: OnboardingDefaultsKey.hasCompleted)
        hasCompleted = false
        currentStep = 0
    }
}
