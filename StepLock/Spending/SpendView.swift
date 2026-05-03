import SwiftUI
import Combine
import FamilyControls
import ManagedSettings

/// Either an app or a category — both are pickable from FamilyActivityPicker
/// and both can be the target of a Spend window.
enum SpendTarget: Hashable {
    case application(ApplicationToken)
    case category(ActivityCategoryToken)
}

struct SpendView: View {
    @State private var shieldManager = ShieldManager.shared
    @State private var wallet = WalletStore.shared
    @State private var unlockStore = UnlockStore.shared

    @State private var selectedTarget: SpendTarget?
    @State private var selectedTier: PricingEngine.Tier?
    @State private var isSpending = false
    @State private var errorText: String?

    @Environment(\.scenePhase) private var scenePhase

    private let tickTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let session = unlockStore.activeSession {
                        activeUnlockBanner(session)
                            .padding(.top, 12)
                    }

                    balanceCard
                        .padding(.top, 12)

                    if !hasAnyGatedSelection {
                        emptyState
                            .padding(.top, 32)
                    } else {
                        sectionLabel("Step 1 — App or category")
                        appPicker
                            .padding(.top, 6)

                        sectionLabel("Step 2 — Duration")
                            .padding(.top, 18)
                        durationTiers
                            .padding(.top, 6)

                        balancePreview
                            .padding(.top, 12)

                        if let errorText {
                            Text(errorText)
                                .font(.system(size: 12))
                                .foregroundStyle(DS.Color.red600)
                                .padding(.top, 8)
                        }

                        spendButton
                            .padding(.top, 12)
                    }
                }
                .padding(.horizontal, DS.Space.edge)
                .padding(.bottom, 24)
            }
            .background(DS.Color.gray0)
            .navigationTitle("Spend points")
            .onAppear { reapExpiry() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { reapExpiry() }
            }
            .onReceive(tickTimer) { _ in
                if unlockStore.activeSession != nil {
                    reapExpiry()
                }
            }
        }
    }

    // MARK: - Subviews

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold))
            .tracking(0.7)
            .foregroundStyle(DS.Color.purple400)
    }

    private var balanceCard: some View {
        HStack {
            Text("Balance")
                .font(.system(size: 13))
                .foregroundStyle(DS.Color.gray600)
            Spacer()
            Text("\(wallet.balance.formatted()) pts")
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(DS.Color.gray900)
                .contentTransition(.numericText(value: Double(wallet.balance)))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(DS.Color.gray50, in: RoundedRectangle(cornerRadius: DS.Radius.r12, style: .continuous))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.app.dashed")
                .font(.system(size: 40))
                .foregroundStyle(DS.Color.gray400)
            Text("No gated apps yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DS.Color.gray900)
            Text("Pick the apps you want to gate in Settings → Manage gated apps. Then come back here to spend points and unlock one.")
                .font(.system(size: 13))
                .foregroundStyle(DS.Color.gray400)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(DS.Color.gray50, in: RoundedRectangle(cornerRadius: DS.Radius.r14, style: .continuous))
    }

    private var appPicker: some View {
        VStack(spacing: 4) {
            ForEach(Array(shieldManager.selection.applicationTokens), id: \.self) { token in
                let target: SpendTarget = .application(token)
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    selectedTarget = target
                } label: {
                    targetRow(label: AnyView(Label(token).labelStyle(.titleAndIcon)),
                              hint: nil,
                              isSelected: selectedTarget == target)
                }
                .buttonStyle(.plain)
            }

            ForEach(Array(shieldManager.selection.categoryTokens), id: \.self) { token in
                let target: SpendTarget = .category(token)
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    selectedTarget = target
                } label: {
                    targetRow(label: AnyView(Label(token).labelStyle(.titleAndIcon)),
                              hint: "Category — unlocks all apps in it",
                              isSelected: selectedTarget == target)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func targetRow(label: AnyView, hint: String?, isSelected: Bool) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                label
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(DS.Color.gray900)
                if let hint {
                    Text(hint)
                        .font(.system(size: 10))
                        .foregroundStyle(DS.Color.gray400)
                }
            }

            Spacer()

            if isSelected {
                ZStack {
                    Circle().fill(DS.Color.purple400).frame(width: 22, height: 22)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                }
            } else {
                Circle()
                    .strokeBorder(DS.Color.gray200, lineWidth: 1.5)
                    .frame(width: 22, height: 22)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            isSelected ? DS.Color.purple50 : DS.Color.gray50,
            in: RoundedRectangle(cornerRadius: DS.Radius.r10, style: .continuous)
        )
    }

    private var hasAnyGatedSelection: Bool {
        !shieldManager.selection.applicationTokens.isEmpty
            || !shieldManager.selection.categoryTokens.isEmpty
    }

    private var durationTiers: some View {
        VStack(spacing: 6) {
            ForEach(PricingEngine.tiers) { tier in
                let canAfford = wallet.balance >= tier.pointsCost
                let isSelected = selectedTier?.id == tier.id

                Button {
                    guard canAfford else { return }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    selectedTier = tier
                } label: {
                    durationCard(tier: tier, isSelected: isSelected, canAfford: canAfford)
                }
                .buttonStyle(.plain)
                .disabled(!canAfford)
            }
        }
    }

    private func durationCard(tier: PricingEngine.Tier, isSelected: Bool, canAfford: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(tier.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DS.Color.gray900)
                Text(tier.hint)
                    .font(.system(size: 11))
                    .foregroundStyle(DS.Color.gray400)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(tier.pointsCost.formatted()) pts")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(canAfford ? DS.Color.purple600 : DS.Color.gray400)
                if !canAfford {
                    Text("need \(tier.pointsCost.formatted())")
                        .font(.system(size: 10))
                        .foregroundStyle(DS.Color.gray400)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            isSelected ? DS.Color.purple50 : DS.Color.gray0,
            in: RoundedRectangle(cornerRadius: DS.Radius.r12, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.r12, style: .continuous)
                .strokeBorder(
                    isSelected ? DS.Color.purple400 : DS.Color.gray100,
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .opacity(canAfford ? 1.0 : 0.45)
    }

    private var balancePreview: some View {
        HStack {
            Text("Balance after")
                .font(.system(size: 12))
                .foregroundStyle(DS.Color.gray600)
            Spacer()
            if let tier = selectedTier {
                Text("\(wallet.balance.formatted()) → \((wallet.balance - tier.pointsCost).formatted())")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(DS.Color.gray900)
            } else {
                Text("\(wallet.balance.formatted())")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(DS.Color.gray400)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(DS.Color.gray50, in: RoundedRectangle(cornerRadius: DS.Radius.r10, style: .continuous))
    }

    private var spendButton: some View {
        Button {
            performSpend()
        } label: {
            HStack(spacing: 8) {
                if isSpending { ProgressView().tint(.white) }
                Text(spendButtonLabel)
            }
        }
        .buttonStyle(DSPrimaryButtonStyle())
        .disabled(!canSpend || isSpending)
        .opacity(canSpend ? 1 : 0.5)
    }

    private var spendButtonLabel: String {
        guard let tier = selectedTier else {
            return selectedTarget == nil ? "Pick an app or category" : "Pick a duration"
        }
        return "Unlock \(tier.title) for \(tier.pointsCost.formatted()) pts"
    }

    private var canSpend: Bool {
        guard let tier = selectedTier, selectedTarget != nil else { return false }
        guard unlockStore.activeSession == nil else { return false }
        return wallet.balance >= tier.pointsCost
    }

    private func activeUnlockBanner(_ session: UnlockSession) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "hourglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(DS.Color.teal400)
            VStack(alignment: .leading, spacing: 2) {
                Text("An app is unlocked")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DS.Color.teal900)
                Text("Time remaining: \(formatRemaining(session.remainingSeconds))")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DS.Color.teal600)
                    .contentTransition(.numericText())
            }
            Spacer()
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                unlockStore.clear()
            } label: {
                Text("End now")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DS.Color.teal900)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(DS.Color.gray0, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(DS.Color.teal50, in: RoundedRectangle(cornerRadius: DS.Radius.r12, style: .continuous))
    }

    private func formatRemaining(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    // MARK: - Actions

    private func performSpend() {
        guard let target = selectedTarget, let tier = selectedTier else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        isSpending = true
        errorText = nil

        do {
            try wallet.debit(points: tier.pointsCost)
            let session: UnlockSession
            switch target {
            case .application(let token):
                session = try UnlockSession.make(
                    applicationToken: token,
                    pointsSpent: tier.pointsCost,
                    durationMinutes: tier.durationMinutes
                )
            case .category(let token):
                session = try UnlockSession.make(
                    categoryToken: token,
                    pointsSpent: tier.pointsCost,
                    durationMinutes: tier.durationMinutes
                )
            }
            unlockStore.start(session)
            LedgerStore.shared.recordSpend(session: session)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            selectedTier = nil
            selectedTarget = nil
        } catch {
            errorText = error.localizedDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }

        isSpending = false
    }

    private func reapExpiry() {
        if unlockStore.reapIfExpired() {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
    }
}

#Preview {
    SpendView()
}
