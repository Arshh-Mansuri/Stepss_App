import SwiftUI

struct OnboardingFlow: View {
    @State private var state = OnboardingState()
    let onComplete: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            DS.Color.gray0.ignoresSafeArea()

            VStack(spacing: 0) {
                OnboardingProgressDots(current: state.currentStep, total: 3)
                    .padding(.top, 8)

                ZStack {
                    switch state.currentStep {
                    case 0:
                        OnboardingConceptView(onContinue: advance)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    case 1:
                        OnboardingPermissionsView(onContinue: advance, onBack: goBack)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    default:
                        OnboardingAppPickerView(onFinish: finish)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                }
                .animation(.spring(response: 0.55, dampingFraction: 0.82), value: state.currentStep)
            }
        }
    }

    private func advance() {
        state.advance()
    }

    private func goBack() {
        state.goBack()
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
