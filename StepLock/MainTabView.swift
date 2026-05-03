import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Today", systemImage: "figure.walk")
                }

            PlaceholderTab(
                title: "Spend",
                subtitle: "Aditya — coming next",
                symbol: "bolt.circle.fill",
                tint: DS.Color.purple600
            )
            .tabItem {
                Label("Spend", systemImage: "bolt.circle.fill")
            }

            PlaceholderTab(
                title: "History",
                subtitle: "Arsh — pending ledger",
                symbol: "clock.arrow.circlepath",
                tint: DS.Color.teal400
            )
            .tabItem {
                Label("History", systemImage: "clock.arrow.circlepath")
            }

            PlaceholderTab(
                title: "Settings",
                subtitle: "Aditya — coming next",
                symbol: "gearshape.fill",
                tint: DS.Color.gray600
            )
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .tint(DS.Color.purple600)
    }
}

private struct PlaceholderTab: View {
    let title: String
    let subtitle: String
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 56, weight: .regular))
                .foregroundStyle(tint)
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(DS.Color.gray900)
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundStyle(DS.Color.gray400)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.Color.gray0)
    }
}

#Preview {
    MainTabView()
}
