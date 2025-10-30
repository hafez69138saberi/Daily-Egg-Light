import SwiftUI

struct TabBarView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        TabView {
            NavigationView { MainView() }
                .tabItem { Label("Home", systemImage: "house") }

            NavigationView { StatsView() }
                .tabItem { Label("Stats", systemImage: "chart.bar") }

            NavigationView { AchievementsView() }
                .tabItem { Label("Achievements", systemImage: "rosette") }

            NavigationView { CategoriesView() }
                .tabItem { Label("Categories", systemImage: "folder") }
        }
        .environmentObject(appViewModel)
    }
}

#Preview {
    TabBarView().environmentObject(AppViewModel())
}


