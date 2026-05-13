import SwiftUI

struct OnboardingFlow: View {
    @State private var state = OnboardingState.shared
    let onComplete: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            DS.Color.gray0.ignoresSafeArea()

            VStack(spacing: 0) {
                OnboardingProgressDots(current: state.currentStep, total: 4)
                    .padding(.top, 8)

                ZStack {
                    switch state.currentStep {
                    case 0:
                        OnboardingConceptView(onContinue: advance)
                            .transition(slideTransition)
                    case 1:
                        OnboardingPermissionsView(onContinue: advance, onBack: goBack)
                            .transition(slideTransition)
                    case 2:
                        OnboardingGoalView(onContinue: handleGoalSelected, onBack: goBack)
                            .transition(slideTransition)
                    default:
                        OnboardingAppPickerView(onFinish: finish)
                            .transition(slideTransition)
                    }
                }
                .animation(.spring(response: 0.55, dampingFraction: 0.82), value: state.currentStep)
            }
        }
    }

    private var slideTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    private func advance() {
        state.advance()
    }

    private func goBack() {
        state.goBack()
    }

    private func handleGoalSelected(_ goal: Int) {
        AppGroup.sharedDefaults.set(goal, forKey: HealthKitConfig.DefaultsKey.dailyStepGoal)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        state.advance()
    }

    private func finish() {
        state.complete()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onComplete()
    }
}

#Preview {
    OnboardingFlow(onComplete: {})
}
