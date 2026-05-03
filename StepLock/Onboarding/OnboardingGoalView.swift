import SwiftUI

struct OnboardingGoalView: View {
    let onContinue: (Int) -> Void
    let onBack: () -> Void

    @State private var appeared = false
    @State private var isLoading = true
    @State private var historyByDate: [Date: Int] = [:]
    @State private var goal: Int = HealthKitConfig.defaultDailyStepGoal
    @State private var hasHistory = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 8)

            VStack(alignment: .leading, spacing: 8) {
                Text("Set your\ndaily goal.")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(DS.Color.gray900)
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(DS.Color.gray400)
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)

            historyCard
                .padding(.top, 20)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 18)

            stepperCard
                .padding(.top, 16)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 24)

            Spacer()

            VStack(spacing: 4) {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onContinue(goal)
                } label: {
                    Text("Set goal — \(goal.formatted()) steps")
                }
                .buttonStyle(DSPrimaryButtonStyle())

                Button("Back", action: onBack)
                    .buttonStyle(DSGhostButtonStyle())
            }
            .padding(.bottom, 8)
            .opacity(appeared ? 1 : 0)
        }
        .padding(.horizontal, DS.Space.edge)
        .task {
            await loadHistory()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.78)) {
                appeared = true
            }
        }
    }

    // MARK: - Subviews

    private var subtitle: String {
        if isLoading {
            return "Reading your last 7 days from Apple Health…"
        }
        if hasHistory {
            return "Based on your recent activity. You can change this any time in Settings."
        }
        return "We don't have step history yet — start with a goal that feels doable."
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LAST 7 DAYS")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(DS.Color.gray400)

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else if hasHistory {
                weekChart
                HStack(spacing: 16) {
                    statBlock(label: "Avg", value: avgSteps)
                    statBlock(label: "Peak", value: peakSteps)
                    statBlock(label: "Days ≥ goal", value: "\(daysHittingGoal)/7")
                }
            } else {
                Text("No step samples in the last week.")
                    .font(.system(size: 12))
                    .foregroundStyle(DS.Color.gray400)
                    .frame(maxWidth: .infinity, minHeight: 80)
            }
        }
        .padding(14)
        .background(DS.Color.gray50, in: RoundedRectangle(cornerRadius: DS.Radius.r14, style: .continuous))
    }

    private var weekChart: some View {
        let entries = sortedHistory
        let maxValue = max(entries.map(\.steps).max() ?? 1, goal)
        return HStack(alignment: .bottom, spacing: 6) {
            ForEach(entries, id: \.date) { entry in
                VStack(spacing: 4) {
                    GeometryReader { geo in
                        VStack {
                            Spacer(minLength: 0)
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(entry.steps >= goal ? DS.Color.teal400 : DS.Color.purple400.opacity(0.7))
                                .frame(height: max(4, CGFloat(entry.steps) / CGFloat(maxValue) * geo.size.height))
                        }
                    }
                    .frame(height: 64)

                    Text(entry.dayLabel)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(DS.Color.gray400)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func statBlock(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(DS.Color.gray400)
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(DS.Color.gray900)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stepperCard: some View {
        HStack(spacing: 12) {
            stepperButton(symbol: "minus") {
                let newValue = max(StepGoalRecommender.minimum, goal - StepGoalRecommender.increment)
                if newValue != goal {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { goal = newValue }
                }
            }

            VStack(spacing: 2) {
                Text("\(goal.formatted())")
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundStyle(DS.Color.purple600)
                    .contentTransition(.numericText(value: Double(goal)))
                Text("steps per day")
                    .font(.system(size: 11))
                    .foregroundStyle(DS.Color.gray400)
            }
            .frame(maxWidth: .infinity)

            stepperButton(symbol: "plus") {
                let newValue = min(StepGoalRecommender.maximum, goal + StepGoalRecommender.increment)
                if newValue != goal {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { goal = newValue }
                }
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 14)
        .background(DS.Color.purple50, in: RoundedRectangle(cornerRadius: DS.Radius.r14, style: .continuous))
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

    // MARK: - Data helpers

    private struct HistoryEntry {
        let date: Date
        let steps: Int
        let dayLabel: String
    }

    private var sortedHistory: [HistoryEntry] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        let lower = Calendar.current.startOfDay(for: Date()).addingTimeInterval(-7 * 86_400)
        return historyByDate
            .filter { $0.key >= lower }
            .sorted { $0.key < $1.key }
            .map { date, count in
                HistoryEntry(date: date, steps: count, dayLabel: String(formatter.string(from: date).prefix(1)))
            }
    }

    private var avgSteps: String {
        let nonZero = sortedHistory.map(\.steps).filter { $0 > 0 }
        guard !nonZero.isEmpty else { return "—" }
        return (nonZero.reduce(0, +) / nonZero.count).formatted()
    }

    private var peakSteps: String {
        (sortedHistory.map(\.steps).max() ?? 0).formatted()
    }

    private var daysHittingGoal: Int {
        sortedHistory.filter { $0.steps >= goal }.count
    }

    private func loadHistory() async {
        do {
            let history = try await HealthKitService.shared.dailyStepHistory(daysBack: 7)
            await MainActor.run {
                self.historyByDate = history
                let values = history.values.sorted()
                self.hasHistory = values.contains(where: { $0 > 0 })
                self.goal = StepGoalRecommender.recommend(from: Array(values))
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.hasHistory = false
                self.goal = HealthKitConfig.defaultDailyStepGoal
                self.isLoading = false
            }
        }
    }
}

#Preview {
    OnboardingGoalView(onContinue: { _ in }, onBack: {})
}
