import SwiftUI
import SwiftData

@main
struct hypeflow_iosApp: App {
    @State private var settings = AppSettings()
    private let client: APIClientProtocol = APIClient()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .task {
                    async let sources: Void = settings.loadSources(client: client)
                    async let health: Void = settings.checkHealth(client: client)
                    _ = await (sources, health)
                }
        }
        .modelContainer(for: [FavoriteTrend.self, SavedSearch.self])
    }
}
