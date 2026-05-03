import SwiftUI

struct HomeView: View {
    @State private var steps: Int = 0
    @State private var isLoading: Bool = true
    @State private var errorText: String?

    @Environment(\.scenePhase) private var scenePhase

    private let dailyGoal = 10_000

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Today")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(DS.Color.gray900)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                Text(Date.now.formatted(.dateTime.weekday(.wide).month().day()))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(DS.Color.gray400)
                    .padding(.bottom, 16)

                // Ring
                HStack {
                    Spacer()
                    StepsRing(steps: steps, goal: dailyGoal)
                        .padding(.vertical, 8)
                    Spacer()
                }

                // Stat tiles
                HStack(spacing: 8) {
                    statTile(
                        label: "Points today",
                        value: "+\(steps)",
                        sub: "1 step = 1 pt",
                        valueColor: DS.Color.teal400
                    )
                    statTile(
                        label: "Balance",
                        value: "—",
                        sub: "ledger pending",
                        valueColor: DS.Color.gray400
                    )
                }
                .padding(.top, 12)

                infoCard
                    .padding(.top, 8)

                Spacer(minLength: 16)

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    // Hand-off to Aditya's Spend tab — implemented post-ledger.
                } label: {
                    HStack {
                        Text("Spend points")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .buttonStyle(DSPrimaryButtonStyle())
                .disabled(true)
                .opacity(0.6)
                .padding(.top, 12)

                if let errorText {
                    Text(errorText)
                        .font(.system(size: 12))
                        .foregroundStyle(DS.Color.red600)
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal, DS.Space.edge)
            .padding(.bottom, 24)
        }
        .background(DS.Color.gray0)
        .task {
            await refreshSteps()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await refreshSteps() }
            }
        }
        .refreshable {
            await refreshSteps()
        }
    }

    private var infoCard: some View {
        let remaining = max(500 - steps, 0)
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Steps to next unlock")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(DS.Color.purple600)
                Text(remaining > 0
                     ? "\(remaining.formatted()) more → afford 15 min"
                     : "You can afford a 15 min unlock!")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DS.Color.purple900)
            }
            Spacer()
            Image(systemName: "lock.open.fill")
                .font(.system(size: 18))
                .foregroundStyle(DS.Color.purple400)
        }
        .padding(14)
        .background(DS.Color.purple50, in: RoundedRectangle(cornerRadius: DS.Radius.r14, style: .continuous))
    }

    private func statTile(label: String, value: String, sub: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(DS.Color.gray400)
            Text(value)
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(valueColor)
            Text(sub)
                .font(.system(size: 11))
                .foregroundStyle(DS.Color.gray400)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(DS.Color.gray50, in: RoundedRectangle(cornerRadius: DS.Radius.r12, style: .continuous))
    }

    private func refreshSteps() async {
        do {
            let value = try await HealthKitService.shared.todayStepCount()
            await MainActor.run {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                    self.steps = value
                }
                self.isLoading = false
                self.errorText = nil
            }
        } catch {
            await MainActor.run {
                self.errorText = "Couldn't read steps — \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}

#Preview {
    HomeView()
}
