import SwiftUI

/// Lets the user pick how many steps earn one point. Shows a live preview
/// based on their last-7-day step average so the choice is grounded in
/// real usage instead of a guess.
struct ConversionRateEditorSheet: View {
    let onSave: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var stepsPerPoint: Int
    @State private var avgDailySteps: Int = 0
    @State private var isLoadingHistory: Bool = true

    init(currentStepsPerPoint: Int, onSave: @escaping (Int) -> Void) {
        self._stepsPerPoint = State(initialValue: currentStepsPerPoint)
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("Steps to point ratio")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(DS.Color.gray900)
                Text("Lower = more generous. Higher = harder to earn.")
                    .font(.system(size: 13))
                    .foregroundStyle(DS.Color.gray400)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 24)

            stepperCard
                .padding(.horizontal, DS.Space.edge)

            previewCard
                .padding(.horizontal, DS.Space.edge)

            Spacer()

            VStack(spacing: 4) {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onSave(stepsPerPoint)
                    dismiss()
                } label: {
                    Text("Save")
                }
                .buttonStyle(DSPrimaryButtonStyle())

                Button("Cancel") { dismiss() }
                    .buttonStyle(DSGhostButtonStyle())
            }
            .padding(.horizontal, DS.Space.edge)
            .padding(.bottom, 16)
        }
        .task { await loadHistory() }
    }

    // MARK: - Stepper

    private var stepperCard: some View {
        HStack(spacing: 12) {
            stepperButton(symbol: "minus") {
                let newValue = max(HealthKitConfig.minStepsPerPoint, stepsPerPoint - 1)
                if newValue != stepsPerPoint {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { stepsPerPoint = newValue }
                }
            }

            VStack(spacing: 2) {
                HStack(spacing: 6) {
                    Text("\(stepsPerPoint)")
                        .font(.system(size: 38, weight: .heavy))
                        .foregroundStyle(DS.Color.purple600)
                        .contentTransition(.numericText(value: Double(stepsPerPoint)))
                    Text(stepsPerPoint == 1 ? "step" : "steps")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DS.Color.gray400)
                        .padding(.bottom, 6)
                    Text("=")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(DS.Color.gray400)
                        .padding(.bottom, 6)
                    Text("1 pt")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(DS.Color.teal400)
                        .padding(.bottom, 6)
                }
            }
            .frame(maxWidth: .infinity)

            stepperButton(symbol: "plus") {
                let newValue = min(HealthKitConfig.maxStepsPerPoint, stepsPerPoint + 1)
                if newValue != stepsPerPoint {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { stepsPerPoint = newValue }
                }
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 14)
        .background(DS.Color.purple50, in: RoundedRectangle(cornerRadius: DS.Radius.r14, style: .continuous))
    }

    // MARK: - Live preview

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AT YOUR LAST-7-DAY AVERAGE")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(DS.Color.gray400)

            if isLoadingHistory {
                HStack {
                    ProgressView()
                    Text("Reading your step history…")
                        .font(.system(size: 12))
                        .foregroundStyle(DS.Color.gray400)
                }
                .padding(.vertical, 10)
            } else if avgDailySteps == 0 {
                Text("No step samples in the last week to preview against. The default of 1:1 will earn one point per step you walk.")
                    .font(.system(size: 12))
                    .foregroundStyle(DS.Color.gray600)
                    .lineSpacing(2)
            } else {
                previewLine(label: "Avg daily steps", value: avgDailySteps.formatted())
                Divider()
                previewLine(label: "Earned per day", value: "\(estimatedDailyPoints.formatted()) pts", emphasised: true)
                Divider()
                previewLine(label: "30-min unlocks per day",
                            value: estimatedDailyUnlocksLabel,
                            sub: "at 900 pts each")
            }
        }
        .padding(14)
        .background(DS.Color.gray50, in: RoundedRectangle(cornerRadius: DS.Radius.r14, style: .continuous))
    }

    private func previewLine(label: String, value: String, sub: String? = nil, emphasised: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 13))
                    .foregroundStyle(DS.Color.gray600)
                if let sub {
                    Text(sub)
                        .font(.system(size: 10))
                        .foregroundStyle(DS.Color.gray400)
                }
            }
            Spacer()
            Text(value)
                .font(.system(size: emphasised ? 17 : 14, weight: emphasised ? .bold : .semibold))
                .foregroundStyle(emphasised ? DS.Color.teal400 : DS.Color.gray900)
                .contentTransition(.numericText())
        }
    }

    // MARK: - Helpers

    private var estimatedDailyPoints: Int {
        avgDailySteps / max(1, stepsPerPoint)
    }

    private var estimatedDailyUnlocksLabel: String {
        let unlocksFloat = Double(estimatedDailyPoints) / 900.0
        if unlocksFloat < 0.5 {
            return "<0.5"
        }
        return String(format: "%.1f", unlocksFloat)
    }

    private func stepperButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(DS.Color.purple600)
                .frame(width: 44, height: 44)
                .background(DS.Color.gray0, in: Circle())
        }
        .buttonStyle(.plain)
    }

    private func loadHistory() async {
        do {
            let history = try await HealthKitService.shared.dailyStepHistory(daysBack: 7)
            let nonZero = history.values.filter { $0 > 0 }
            await MainActor.run {
                if nonZero.isEmpty {
                    avgDailySteps = 0
                } else {
                    avgDailySteps = nonZero.reduce(0, +) / nonZero.count
                }
                isLoadingHistory = false
            }
        } catch {
            await MainActor.run {
                avgDailySteps = 0
                isLoadingHistory = false
            }
        }
    }
}
