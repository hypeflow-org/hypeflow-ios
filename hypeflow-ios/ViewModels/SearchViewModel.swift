import Foundation

@MainActor
@Observable
final class SearchViewModel {
    var query = ""
    var popular: [PopularWordDTO] = []
    var state: LoadState<TimeseriesResponseDTO> = .idle
    var alertMessage: String?

    private(set) var successCount = 0
    private(set) var lastSearchedQuery = ""

    private let client: APIClientProtocol
    private var currentTask: Task<Void, Never>?

    init(client: APIClientProtocol? = nil) {
        self.client = client ?? APIClient()
    }

    func resetToIdle() {
        currentTask?.cancel()
        state = .idle
        query = ""
    }

    func loadPopular() async {
        do {
            popular = try await client.fetchPopular(limit: 10)
        } catch {
            popular = []
        }
    }

    func search(settings: AppSettings, sourceOverride: [String]? = nil) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.count >= 2 else {
            alertMessage = "Please enter at least 2 characters."
            return
        }

        let isNewQuery = trimmed.lowercased() != lastSearchedQuery.lowercased()

        currentTask?.cancel()
        currentTask = Task { @MainActor in
            state = .loading

            let request = settings.makeTimeseriesRequest(
                word: trimmed,
                sourceOverride: sourceOverride
            )

            do {
                let response = try await client.fetchTimeseries(request)
                guard !Task.isCancelled else { return }
                settings.reportAPIResult(error: nil)
                if response.totalMentions == 0 && response.dailyStatistics.isEmpty {
                    state = .empty
                } else {
                    state = .success(response)
                }
                lastSearchedQuery = trimmed
                if isNewQuery {
                    successCount += 1
                }
            } catch is CancellationError {
                // cancelled - do nothing
            } catch {
                guard !Task.isCancelled else { return }
                settings.reportAPIResult(error: error)
                alertMessage = (error as? LocalizedError)?.errorDescription
                    ?? error.localizedDescription
                state = .error(error)
            }
        }
    }
}
