import SwiftUI
import FamilyControls

struct OnboardingPermissionsView: View {
    let onContinue: () -> Void
    let onBack: () -> Void

    @State private var appeared = false
    @State private var pulseHealth = false
    @State private var pulseScreenTime = false
    @State private var isRequesting = false
    @State private var errorText: String?

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 8)

            VStack(alignment: .leading, spacing: 10) {
                Text("Two permissions,\nthat's it.")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(DS.Color.gray900)
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)

            VStack(spacing: 12) {
                permissionCard(
                    title: "Apple Health",
                    sub: "Step count only",
                    body: "We read steps — nothing else. No heart rate, sleep, or any other health data.",
                    icon: "heart.fill",
                    iconBg: DS.Color.teal400,
                    cardBg: DS.Color.teal50,
                    headlineColor: DS.Color.teal900,
                    bodyColor: DS.Color.teal600,
                    pulse: $pulseHealth
                )
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 18)

                permissionCard(
                    title: "Screen Time",
                    sub: "App blocking via Apple API",
                    body: "Apple controls all blocking. StepLock only schedules timed windows — no bypasses, ever.",
                    icon: "lock.fill",
                    iconBg: DS.Color.purple600,
                    cardBg: DS.Color.purple50,
                    headlineColor: DS.Color.purple900,
                    bodyColor: DS.Color.purple600,
                    pulse: $pulseScreenTime
                )
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 28)
            }
            .padding(.top, 24)

            if let errorText {
                Text(errorText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DS.Color.red600)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    .transition(.opacity)
            }

            Spacer()

            VStack(spacing: 4) {
                Button(action: requestPermissions) {
                    HStack(spacing: 8) {
                        if isRequesting {
                            ProgressView().tint(.white)
                        }
                        Text(isRequesting ? "Requesting…" : "Allow both & continue")
                    }
                }
                .buttonStyle(DSPrimaryButtonStyle(background: DS.Color.gray900, foreground: .white))
                .disabled(isRequesting)

                Button("Back", action: onBack)
                    .buttonStyle(DSGhostButtonStyle())
            }
            .padding(.bottom, 8)
            .opacity(appeared ? 1 : 0)
        }
        .padding(.horizontal, DS.Space.edge)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.78)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulseHealth = true
            }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true).delay(0.4)) {
                pulseScreenTime = true
            }
        }
    }

    private func permissionCard(
        title: String,
        sub: String,
        body: String,
        icon: String,
        iconBg: Color,
        cardBg: Color,
        headlineColor: Color,
        bodyColor: Color,
        pulse: Binding<Bool>
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(iconBg)
                        .frame(width: 44, height: 44)
                        .scaleEffect(pulse.wrappedValue ? 1.04 : 1.0)
                        .shadow(color: iconBg.opacity(0.4), radius: 10, y: 4)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(headlineColor)
                    Text(sub)
                        .font(.system(size: 12))
                        .foregroundStyle(bodyColor)
                }
                Spacer()
            }
            Text(body)
                .font(.system(size: 13))
                .foregroundStyle(bodyColor)
                .lineSpacing(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(cardBg, in: RoundedRectangle(cornerRadius: DS.Radius.r14, style: .continuous))
    }

    private func requestPermissions() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        // 🧪 DEV MODE: Skip permissions in simulator
        if DevConfig.bypassPermissions {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.onContinue()
            }
            return
        }
        isRequesting = true
        errorText = nil

        Task {
            // Apple Health — read steps
            do {
                try await HealthKitService.shared.requestAuthorization()
                try await HealthKitService.shared.start()
            } catch {
                await MainActor.run {
                    errorText = "HealthKit not available — \(error.localizedDescription)"
                    isRequesting = false
                }
                return
            }

            // FamilyControls — app blocking auth
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            } catch {
                await MainActor.run {
                    errorText = "Screen Time auth was declined. You can enable it later in Settings."
                    isRequesting = false
                }
                return
            }

            await MainActor.run {
                isRequesting = false
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                onContinue()
            }
        }
    }
}

#Preview {
    OnboardingPermissionsView(onContinue: {}, onBack: {})
}
