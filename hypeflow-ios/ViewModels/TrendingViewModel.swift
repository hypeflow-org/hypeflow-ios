import Foundation

@MainActor
@Observable
final class TrendingViewModel {
    var state: LoadState<[TrendUI]> = .idle
    var alertMessage: String?

    private let client: APIClientProtocol

    init(client: APIClientProtocol = APIClient()) {
        self.client = client
    }

    func loadTrends(isRefresh: Bool = false) async {
        if !isRefresh {
            state = .loading
        }

        do {
            let dtos = try await client.fetchTrending()
            let trends = dtos.map { $0.toTrendUI() }
            state = trends.isEmpty ? .empty : .success(trends)
        } catch {
            alertMessage = (error as? LocalizedError)?.errorDescription
                ?? error.localizedDescription

            if isRefresh, case .success = state {
                return
            }
            state = .error(error)
        }
    }
}
