import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Today", systemImage: "figure.walk")
                }

            SpendView()
                .tabItem {
                    Label("Spend", systemImage: "bolt.circle.fill")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }

            SettingsView()
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
