import SwiftUI

struct StepsRing: View {
    let steps: Int
    let goal: Int

    var progress: Double {
        guard goal > 0 else { return 0 }
        return min(Double(steps) / Double(goal), 1.0)
    }

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(DS.Color.gray100, lineWidth: 14)

            // Progress
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [DS.Color.teal400, DS.Color.teal600, DS.Color.teal400]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.9, dampingFraction: 0.85), value: progress)

            // Center text
            VStack(spacing: 4) {
                Text("\(steps)")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(DS.Color.gray900)
                    .contentTransition(.numericText(value: Double(steps)))
                Text("of \(goal.formatted()) steps")
                    .font(.system(size: 12))
                    .foregroundStyle(DS.Color.gray400)
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(DS.Color.teal400)
                    .padding(.top, 2)
            }
        }
        .frame(width: 200, height: 200)
    }
}

#Preview {
    VStack(spacing: 32) {
        StepsRing(steps: 0, goal: 10000)
        StepsRing(steps: 7842, goal: 10000)
        StepsRing(steps: 12500, goal: 10000)
    }
    .padding()
}
