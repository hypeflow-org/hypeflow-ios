import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            Tab("Trending", systemImage: "flame.fill") {
                NavigationStack {
                    TrendingView()
                }
            }

            Tab("Search", systemImage: "magnifyingglass") {
                NavigationStack {
                    SearchView()
                }
            }

            Tab("Saved", systemImage: "bookmark.fill") {
                NavigationStack {
                    SavedView()
                }
            }

            Tab("Settings", systemImage: "gearshape.fill") {
                NavigationStack {
                    SettingsView()
                }
            }
        }
    }
}

#Preview {
    RootView()
}
