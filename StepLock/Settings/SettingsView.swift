import SwiftUI
import FamilyControls
import HealthKit

struct SettingsView: View {
    @State private var shieldManager = ShieldManager.shared
    @State private var onboarding = OnboardingState.shared

    @State private var hkState: ConnectionState = .checking
    @State private var screenTimeState: ConnectionState = .checking
    @State private var isPickerPresented = false
    @State private var showResetConfirm = false
    @State private var showResetBalanceConfirm = false
    @State private var showGoalSheet = false
    @State private var showRateSheet = false
    @State private var dailyGoal: Int = HealthKitConfig.defaultDailyStepGoal
    @State private var stepsPerPoint: Int = HealthKitConfig.defaultStepsPerPoint
    @State private var wallet = WalletStore.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    sectionHeader("Connections")
                    connectionsCard

                    sectionHeader("Earning")
                    earningCard

                    sectionHeader("Gated apps")
                    gatedAppsCard

                    sectionHeader("Developer")
                    developerCard

                    Text("StepLock v1.0 · All data on-device")
                        .font(.system(size: 11))
                        .foregroundStyle(DS.Color.gray400)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                        .padding(.bottom, 16)
                }
                .padding(.horizontal, DS.Space.edge)
            }
            .background(DS.Color.gray0)
            .navigationTitle("Settings")
            .familyActivityPicker(isPresented: $isPickerPresented, selection: $shieldManager.selection)
            .sheet(isPresented: $showGoalSheet) {
                StepGoalEditorSheet(currentGoal: dailyGoal) { newGoal in
                    AppGroup.sharedDefaults.set(newGoal, forKey: HealthKitConfig.DefaultsKey.dailyStepGoal)
                    dailyGoal = newGoal
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showRateSheet) {
                ConversionRateEditorSheet(currentStepsPerPoint: stepsPerPoint) { newRate in
                    AppGroup.sharedDefaults.set(newRate, forKey: HealthKitConfig.DefaultsKey.stepsPerPoint)
                    stepsPerPoint = newRate
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
                .presentationDetents([.medium, .large])
            }
            .task {
                loadGoal()
                await refreshAll()
            }
            .refreshable {
                await refreshAll()
            }
            .alert("Reset onboarding?", isPresented: $showResetConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    onboarding.reset()
                }
            } message: {
                Text("Sends you back to the first onboarding screen. Your gated apps stay; only the onboarding flag is cleared.")
            }
            .alert("Reset point balance?", isPresented: $showResetBalanceConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    wallet.reset()
                }
            } message: {
                Text("Sets your balance back to 0 points. Future steps will start fresh from there.")
            }
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .bold))
            .tracking(0.6)
            .foregroundStyle(DS.Color.gray400)
            .padding(.top, 18)
            .padding(.bottom, 6)
    }

    private var connectionsCard: some View {
        VStack(spacing: 0) {
            ConnectionStatusRow(
                title: "Apple Health",
                subtitle: "Step count read access",
                symbol: "heart.fill",
                symbolBg: DS.Color.teal400,
                state: hkState
            )
            Divider().padding(.leading, 60)
            ConnectionStatusRow(
                title: "Screen Time",
                subtitle: "FamilyControls authorization",
                symbol: "lock.fill",
                symbolBg: DS.Color.purple600,
                state: screenTimeState
            )
        }
        .background(DS.Color.gray50, in: RoundedRectangle(cornerRadius: DS.Radius.r12, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Button {
                Task { await refreshAll() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DS.Color.purple600)
                    .padding(8)
            }
        }
    }

    private var earningCard: some View {
        VStack(spacing: 0) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showGoalSheet = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily step goal")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(DS.Color.gray900)
                        Text("\(dailyGoal.formatted()) steps per day")
                            .font(.system(size: 11))
                            .foregroundStyle(DS.Color.gray400)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(DS.Color.gray400)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Divider().padding(.leading, 14)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showRateSheet = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Conversion rate")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(DS.Color.gray900)
                        Text(rateSubtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(DS.Color.gray400)
                    }
                    Spacer()
                    Text("\(stepsPerPoint):1")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(DS.Color.teal400)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(DS.Color.gray400)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Divider().padding(.leading, 14)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current balance")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(DS.Color.gray900)
                    Text("Total points earned, less anything spent")
                        .font(.system(size: 11))
                        .foregroundStyle(DS.Color.gray400)
                }
                Spacer()
                Text(wallet.balance.formatted())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(DS.Color.gray900)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
        }
        .background(DS.Color.gray50, in: RoundedRectangle(cornerRadius: DS.Radius.r12, style: .continuous))
    }

    private var gatedAppsCard: some View {
        VStack(spacing: 0) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                isPickerPresented = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Manage gated apps")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(DS.Color.gray900)
                        Text(selectionSummary)
                            .font(.system(size: 11))
                            .foregroundStyle(DS.Color.gray400)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(DS.Color.gray400)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .background(DS.Color.gray50, in: RoundedRectangle(cornerRadius: DS.Radius.r12, style: .continuous))
    }

    private var developerCard: some View {
        VStack(spacing: 0) {
            destructiveRow(
                title: "Reset onboarding",
                subtitle: "Re-shows the 4 setup screens on next launch",
                symbol: "arrow.counterclockwise.circle.fill"
            ) {
                showResetConfirm = true
            }

            Divider().padding(.leading, 14)

            destructiveRow(
                title: "Reset balance",
                subtitle: "Clears the point balance back to 0",
                symbol: "minus.circle.fill"
            ) {
                showResetBalanceConfirm = true
            }
        }
        .background(DS.Color.gray50, in: RoundedRectangle(cornerRadius: DS.Radius.r12, style: .continuous))
    }

    private func destructiveRow(title: String, subtitle: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(DS.Color.red600)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(DS.Color.gray400)
                }
                Spacer()
                Image(systemName: symbol)
                    .font(.system(size: 16))
                    .foregroundStyle(DS.Color.red600.opacity(0.7))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Selection summary

    private var selectionSummary: String {
        let apps = shieldManager.selection.applicationTokens.count
        let cats = shieldManager.selection.categoryTokens.count
        switch (apps, cats) {
        case (0, 0): return "Nothing selected — tap to pick"
        case (let a, 0): return "\(a) app\(a == 1 ? "" : "s")"
        case (0, let c): return "\(c) categor\(c == 1 ? "y" : "ies")"
        case (let a, let c): return "\(a) app\(a == 1 ? "" : "s") · \(c) categor\(c == 1 ? "y" : "ies")"
        }
    }

    // MARK: - Goal + rate

    private func loadGoal() {
        let stored = AppGroup.sharedDefaults.integer(forKey: HealthKitConfig.DefaultsKey.dailyStepGoal)
        dailyGoal = stored > 0 ? stored : HealthKitConfig.defaultDailyStepGoal

        let storedRate = AppGroup.sharedDefaults.integer(forKey: HealthKitConfig.DefaultsKey.stepsPerPoint)
        stepsPerPoint = storedRate > 0 ? storedRate : HealthKitConfig.defaultStepsPerPoint
    }

    private var rateSubtitle: String {
        if stepsPerPoint == 1 {
            return "1 step earns 1 point — most generous"
        }
        return "\(stepsPerPoint) steps earn 1 point"
    }

    // MARK: - Connection checks

    private func refreshAll() async {
        await MainActor.run {
            hkState = .checking
            screenTimeState = .checking
        }
        await checkHealthKit()
        await checkScreenTime()
    }

    private func checkHealthKit() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            await MainActor.run {
                hkState = .failed(detail: "Unavailable on this device")
            }
            return
        }
        do {
            let count = try await HealthKitService.shared.todayStepCount()
            await MainActor.run {
                hkState = .connected(detail: "\(count) today")
            }
        } catch {
            await MainActor.run {
                hkState = .failed(detail: "Read failed")
            }
        }
    }

    private func checkScreenTime() async {
        let status = AuthorizationCenter.shared.authorizationStatus
        await MainActor.run {
            switch status {
            case .approved:
                screenTimeState = .connected(detail: "Approved")
            case .denied:
                screenTimeState = .failed(detail: "Denied")
            case .notDetermined:
                screenTimeState = .warning(detail: "Not requested")
            @unknown default:
                screenTimeState = .warning(detail: "Unknown")
            }
        }
    }
}

#Preview {
    SettingsView()
}
