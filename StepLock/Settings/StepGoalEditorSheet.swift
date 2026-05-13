import SwiftUI

struct StepGoalEditorSheet: View {
    let currentGoal: Int
    let onSave: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var goal: Int

    init(currentGoal: Int, onSave: @escaping (Int) -> Void) {
        self.currentGoal = currentGoal
        self.onSave = onSave
        self._goal = State(initialValue: currentGoal)
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 4) {
                Text("Daily step goal")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(DS.Color.gray900)
                Text("Used by the Today ring. Change anytime.")
                    .font(.system(size: 13))
                    .foregroundStyle(DS.Color.gray400)
            }
            .padding(.top, 24)

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
                        .font(.system(size: 38, weight: .heavy))
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
            .padding(.horizontal, DS.Space.edge)

            Spacer()

            VStack(spacing: 4) {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onSave(goal)
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
}
