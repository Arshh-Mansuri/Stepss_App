import SwiftUI
import FamilyControls

struct OnboardingAppPickerView: View {
    let onFinish: () -> Void

    @State private var appeared = false
    @State private var isPickerPresented = false
    @State private var shieldManager = ShieldManager.shared
    @State private var swirl = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 8)

            VStack(alignment: .leading, spacing: 8) {
                Text("Pick the apps\nyou want to gate.")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(DS.Color.gray900)
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("You choose. Apple shows the names. StepLock never sees them.")
                    .font(.system(size: 14))
                    .foregroundStyle(DS.Color.gray400)
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)

            // Apple System Picker placeholder
            VStack(spacing: 14) {
                Text("APPLE SYSTEM PICKER")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(DS.Color.gray400)

                HStack(spacing: 12) {
                    tokenChip(bg: DS.Color.gray100, fill: DS.Color.gray400)
                    tokenChip(bg: DS.Color.purple50, fill: DS.Color.purple400)
                    tokenChip(bg: DS.Color.teal50, fill: DS.Color.teal400)
                }
                .scaleEffect(swirl ? 1.04 : 1.0)

                if shieldManager.selection.applicationTokens.count + shieldManager.selection.categoryTokens.count > 0 {
                    selectedBadge
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text("iOS renders each app's\nreal icon & name here")
                        .font(.system(size: 12))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(DS.Color.gray400)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.r14, style: .continuous)
                    .fill(DS.Color.gray50)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.r14, style: .continuous)
                            .strokeBorder(DS.Color.gray200, style: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    )
            )
            .padding(.top, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 22)

            Text("You can add or remove apps any time from Settings")
                .font(.system(size: 12))
                .multilineTextAlignment(.center)
                .foregroundStyle(DS.Color.gray400)
                .padding(.top, 18)
                .opacity(appeared ? 1 : 0)

            Spacer()

            VStack(spacing: 4) {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    isPickerPresented = true
                } label: {
                    Text(hasSelection ? "Done — finish setup" : "Open app picker")
                }
                .buttonStyle(DSPrimaryButtonStyle())
                .familyActivityPicker(isPresented: $isPickerPresented, selection: $shieldManager.selection)
                .onChange(of: hasSelection) { _, newValue in
                    if newValue {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                }

                Button(hasSelection ? "Continue" : "Skip — set up later") {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onFinish()
                }
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
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                swirl = true
            }
        }
    }

    private var hasSelection: Bool {
        shieldManager.selection.applicationTokens.count + shieldManager.selection.categoryTokens.count > 0
    }

    private var selectedBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(DS.Color.teal400)
            let appCount = shieldManager.selection.applicationTokens.count
            let catCount = shieldManager.selection.categoryTokens.count
            Text("\(appCount) app\(appCount == 1 ? "" : "s")\(catCount > 0 ? " · \(catCount) categor\(catCount == 1 ? "y" : "ies")" : "") selected")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DS.Color.teal900)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(DS.Color.teal50, in: Capsule())
    }

    private func tokenChip(bg: Color, fill: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(bg)
                .frame(width: 56, height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(DS.Color.gray200, lineWidth: 0.5)
                )
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(fill.opacity(0.5))
                .frame(width: 22, height: 22)
        }
    }
}

#Preview {
    OnboardingAppPickerView(onFinish: {})
}
