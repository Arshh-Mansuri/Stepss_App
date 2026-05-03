import SwiftUI

struct OnboardingProgressDots: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { idx in
                let isOn = idx == current
                Capsule()
                    .fill(isOn ? DS.Color.purple400 : DS.Color.gray200)
                    .frame(width: isOn ? 22 : 6, height: 6)
                    .animation(.spring(response: 0.45, dampingFraction: 0.7), value: current)
            }
        }
        .padding(.top, 12)
    }
}
