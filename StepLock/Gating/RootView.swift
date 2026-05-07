import SwiftUI

struct RootView: View {
    @State private var onboarding = OnboardingState.shared
    @State private var appearance = AppearanceStore.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            if onboarding.hasCompleted {
                MainTabView()
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
            } else {
                OnboardingFlow {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        onboarding.hasCompleted = true
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.82), value: onboarding.hasCompleted)
        .preferredColorScheme(appearance.preference.colorScheme)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                UnlockStore.shared.reapIfExpired()
            }
        }
    }
}
