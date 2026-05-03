import SwiftUI

struct OnboardingConceptView: View {
    let onContinue: () -> Void

    @State private var heroAppeared = false
    @State private var bouncedHero = 0
    @State private var arrowPulse = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            // Hero icon — purple square with a bolt
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(DS.Color.purple50)
                    .frame(width: 100, height: 100)
                    .shadow(color: DS.Color.purple200.opacity(0.5), radius: 22, y: 10)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(DS.Color.purple600)
                    .symbolEffect(.bounce.up.byLayer, options: .nonRepeating, value: bouncedHero)
            }
            .scaleEffect(heroAppeared ? 1 : 0.7)
            .opacity(heroAppeared ? 1 : 0)

            VStack(spacing: 10) {
                Text("Walk more,\nscroll less.")
                    .font(.system(size: 32, weight: .heavy))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(DS.Color.gray900)
                    .padding(.top, 28)
                    .lineSpacing(2)

                Text("StepLock turns your steps into screen time. No steps, no scroll.")
                    .font(.system(size: 15))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(DS.Color.gray400)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
            }
            .opacity(heroAppeared ? 1 : 0)
            .offset(y: heroAppeared ? 0 : 14)

            // Flow: Walk → Earn → Unlock
            HStack(spacing: 0) {
                flowStep(symbol: "figure.walk",
                         label: "Walk\nsteps",
                         tintBg: DS.Color.teal50,
                         tint: DS.Color.teal600)
                flowArrow
                flowStep(symbol: "sparkles",
                         label: "Earn\npoints",
                         tintBg: DS.Color.purple50,
                         tint: DS.Color.purple600)
                flowArrow
                flowStep(symbol: "iphone",
                         label: "Unlock\napps",
                         tintBg: DS.Color.gray100,
                         tint: DS.Color.gray600)
            }
            .padding(.top, 36)
            .padding(.horizontal, 16)
            .opacity(heroAppeared ? 1 : 0)
            .offset(y: heroAppeared ? 0 : 24)

            Spacer()

            VStack(spacing: 8) {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onContinue()
                } label: {
                    Text("Get started")
                }
                .buttonStyle(DSPrimaryButtonStyle())

                Text("Requires Screen Time & Health access")
                    .font(.system(size: 12))
                    .foregroundStyle(DS.Color.gray400)
                    .padding(.top, 4)
            }
            .padding(.bottom, 8)
            .opacity(heroAppeared ? 1 : 0)
        }
        .padding(.horizontal, DS.Space.edge)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.75)) {
                heroAppeared = true
            }
            // Cute follow-up bounce after the entrance settles.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                bouncedHero += 1
            }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                arrowPulse = true
            }
        }
    }

    private func flowStep(symbol: String, label: String, tintBg: Color, tint: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(tintBg)
                    .frame(width: 56, height: 56)
                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(tint)
            }
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(tint)
                .lineSpacing(1)
        }
        .frame(maxWidth: .infinity)
    }

    private var flowArrow: some View {
        Image(systemName: "arrow.right")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(DS.Color.gray200)
            .opacity(arrowPulse ? 1 : 0.45)
            .padding(.bottom, 18)
    }
}

#Preview {
    OnboardingConceptView(onContinue: {})
}
