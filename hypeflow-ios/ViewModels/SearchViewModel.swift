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

    init(client: APIClientProtocol = APIClient()) {
        self.client = client
    }

    func resetToIdle() {
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

    func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespaces)

        guard trimmed.count >= 2 else {
            alertMessage = "Please enter at least 2 characters."
            return
        }

        state = .loading

        let calendar = Calendar.current
        let endDate = Date()
        let storedTimeframe = UserDefaults.standard.integer(forKey: "timeframe")
        let days = storedTimeframe > 0 ? storedTimeframe : 7
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"

        let sourcesRaw = UserDefaults.standard.string(forKey: "enabledSourceIds") ?? ""
        let enabledSources: [String]? = sourcesRaw.isEmpty
            ? nil
            : sourcesRaw.split(separator: ",").map(String.init)

        let request = TimeseriesRequestDTO(
            word: trimmed,
            startDate: formatter.string(from: startDate),
            endDate: formatter.string(from: endDate),
            sources: enabledSources
        )

        do {
            let response = try await client.fetchTimeseries(request)
            if response.totalMentions == 0 && response.dailyStatistics.isEmpty {
                state = .empty
            } else {
                state = .success(response)
            }
            lastSearchedQuery = trimmed
            successCount += 1
        } catch {
            alertMessage = (error as? LocalizedError)?.errorDescription
                ?? error.localizedDescription
            state = .error(error)
        }
    }
}
