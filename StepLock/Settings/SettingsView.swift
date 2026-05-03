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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    sectionHeader("Connections")
                    connectionsCard

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
            .task {
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
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showResetConfirm = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reset onboarding")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(DS.Color.red600)
                        Text("Re-shows the 3 setup screens on next launch")
                            .font(.system(size: 11))
                            .foregroundStyle(DS.Color.gray400)
                    }
                    Spacer()
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(DS.Color.red600.opacity(0.7))
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .background(DS.Color.gray50, in: RoundedRectangle(cornerRadius: DS.Radius.r12, style: .continuous))
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
