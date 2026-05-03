import SwiftUI
import FamilyControls
import ManagedSettings

struct HistoryView: View {
    @State private var ledger = LedgerStore.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if ledger.entries.isEmpty {
                        emptyState
                            .padding(.top, 40)
                    } else {
                        weekSummaryCard
                            .padding(.top, 12)

                        ForEach(groupedSections, id: \.title) { section in
                            sectionHeader(section.title)
                                .padding(.top, 18)
                            entriesCard(section.entries)
                                .padding(.top, 6)
                        }
                    }
                }
                .padding(.horizontal, DS.Space.edge)
                .padding(.bottom, 24)
            }
            .background(DS.Color.gray0)
            .navigationTitle("History")
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 14) {
            HStack(spacing: 16) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 36))
                    .foregroundStyle(DS.Color.teal400)
                Image(systemName: "lock.open.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(DS.Color.purple400)
            }
            Text("No activity yet")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(DS.Color.gray900)
            Text("Walk a few steps or unlock an app — the receipts show up here.")
                .font(.system(size: 13))
                .foregroundStyle(DS.Color.gray400)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(DS.Color.gray50, in: RoundedRectangle(cornerRadius: DS.Radius.r14, style: .continuous))
    }

    // MARK: - This-week summary

    private var weekSummaryCard: some View {
        let stats = weekStats
        return VStack(alignment: .leading, spacing: 6) {
            Text("THIS WEEK")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(DS.Color.teal600)
            HStack(alignment: .firstTextBaseline, spacing: 14) {
                summaryStat(label: "Earned", value: "+\(stats.earned.formatted())", color: DS.Color.teal400)
                summaryStat(label: "Spent",  value: "−\(stats.spent.formatted())",  color: DS.Color.purple600)
                summaryStat(label: "Net",    value: stats.net >= 0 ? "+\(stats.net.formatted())" : "\(stats.net.formatted())",
                            color: DS.Color.gray900)
            }
        }
        .padding(14)
        .background(DS.Color.teal50, in: RoundedRectangle(cornerRadius: DS.Radius.r14, style: .continuous))
    }

    private func summaryStat(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(DS.Color.gray600)
            Text(value)
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Section header

    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .bold))
            .tracking(0.6)
            .foregroundStyle(DS.Color.gray400)
    }

    // MARK: - Entry rows

    private func entriesCard(_ entries: [LedgerEntry]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                entryRow(entry)
                if index < entries.count - 1 {
                    Divider().padding(.leading, 56)
                }
            }
        }
        .background(DS.Color.gray50, in: RoundedRectangle(cornerRadius: DS.Radius.r12, style: .continuous))
    }

    @ViewBuilder
    private func entryRow(_ entry: LedgerEntry) -> some View {
        switch entry {
        case .earn(let p):  earnRow(p)
        case .spend(let p): spendRow(p)
        }
    }

    private func earnRow(_ p: LedgerEntry.EarnPayload) -> some View {
        HStack(alignment: .top, spacing: 12) {
            iconBubble(symbol: "bolt.fill", bg: DS.Color.teal50, fg: DS.Color.teal600)
            VStack(alignment: .leading, spacing: 2) {
                Text("Earned from walking")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DS.Color.gray900)
                Text("\(p.stepDelta.formatted()) steps · \(relativeTime(p.occurredAt))")
                    .font(.system(size: 11))
                    .foregroundStyle(DS.Color.gray400)
            }
            Spacer()
            Text("+\(p.pointsEarned.formatted())")
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(DS.Color.teal400)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
    }

    private func spendRow(_ p: LedgerEntry.SpendPayload) -> some View {
        HStack(alignment: .top, spacing: 12) {
            iconBubble(symbol: "lock.open.fill", bg: DS.Color.purple50, fg: DS.Color.purple600)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Unlocked \(p.durationMinutes) min")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DS.Color.gray900)
                }
                spendTargetLabel(p)
                Text(relativeTime(p.occurredAt))
                    .font(.system(size: 11))
                    .foregroundStyle(DS.Color.gray400)
            }
            Spacer()
            Text("−\(p.pointsSpent.formatted())")
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(DS.Color.purple600)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
    }

    @ViewBuilder
    private func spendTargetLabel(_ p: LedgerEntry.SpendPayload) -> some View {
        switch p.kind {
        case .application:
            if let token = try? PropertyListDecoder().decode(ApplicationToken.self, from: p.tokenData) {
                Label(token)
                    .labelStyle(.titleOnly)
                    .font(.system(size: 11))
                    .foregroundStyle(DS.Color.gray400)
            }
        case .category:
            if let token = try? PropertyListDecoder().decode(ActivityCategoryToken.self, from: p.tokenData) {
                Label(token)
                    .labelStyle(.titleOnly)
                    .font(.system(size: 11))
                    .foregroundStyle(DS.Color.gray400)
            }
        }
    }

    private func iconBubble(symbol: String, bg: Color, fg: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(bg)
                .frame(width: 32, height: 32)
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(fg)
        }
    }

    // MARK: - Grouping

    private struct Section {
        let title: String
        let entries: [LedgerEntry]
    }

    private var groupedSections: [Section] {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        guard let startOfWeek = calendar.date(byAdding: .day, value: -6, to: startOfToday) else {
            return [Section(title: "All", entries: ledger.entries)]
        }

        var today: [LedgerEntry] = []
        var thisWeek: [LedgerEntry] = []
        var earlier: [LedgerEntry] = []

        for entry in ledger.entries {
            if entry.occurredAt >= startOfToday {
                today.append(entry)
            } else if entry.occurredAt >= startOfWeek {
                thisWeek.append(entry)
            } else {
                earlier.append(entry)
            }
        }

        var sections: [Section] = []
        if !today.isEmpty    { sections.append(Section(title: "Today", entries: today)) }
        if !thisWeek.isEmpty { sections.append(Section(title: "Earlier this week", entries: thisWeek)) }
        if !earlier.isEmpty  { sections.append(Section(title: "Earlier", entries: earlier)) }
        return sections
    }

    // MARK: - Stats

    private struct WeekStats { let earned: Int; let spent: Int; let net: Int }

    private var weekStats: WeekStats {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        guard let startOfWeek = calendar.date(byAdding: .day, value: -6, to: startOfToday) else {
            return WeekStats(earned: 0, spent: 0, net: 0)
        }
        var earned = 0
        var spent = 0
        for entry in ledger.entries where entry.occurredAt >= startOfWeek {
            switch entry {
            case .earn(let p):  earned += p.pointsEarned
            case .spend(let p): spent  += p.pointsSpent
            }
        }
        return WeekStats(earned: earned, spent: spent, net: earned - spent)
    }

    // MARK: - Helpers

    private func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    HistoryView()
}
