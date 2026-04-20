import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }

            NavigationStack {
                DeckDashboardView()
            }
            .tabItem {
                Label("Decks", systemImage: "square.stack")
            }

            NavigationStack {
                StudyView()
            }
            .tabItem {
                Label("Study", systemImage: "book")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(DeckStore())
}
