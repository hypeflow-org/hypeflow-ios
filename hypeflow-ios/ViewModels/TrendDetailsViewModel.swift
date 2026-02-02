import Foundation

@MainActor
@Observable
final class TrendDetailsViewModel {
    var timeseriesState: LoadState<TimeseriesResponseDTO> = .idle

    private let client: APIClientProtocol
    private let keyword: String

    init(keyword: String, initialTimeseries: TimeseriesResponseDTO? = nil,
         client: APIClientProtocol = APIClient()) {
        self.keyword = keyword
        self.client = client
        if let initial = initialTimeseries {
            timeseriesState = .success(initial)
        }
    }

    func loadIfNeeded() async {
        guard case .idle = timeseriesState else { return }
        timeseriesState = .loading
        await fetchTimeseries()
    }

    func reload() async {
        timeseriesState = .loading
        await fetchTimeseries()
    }

    private func fetchTimeseries() async {

        let storedTimeframe = UserDefaults.standard.integer(forKey: "timeframe")
        let days = storedTimeframe > 0 ? storedTimeframe : 7

        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"

        let sourcesRaw = UserDefaults.standard.string(forKey: "enabledSourceIds") ?? ""
        let enabledSources: [String]? = sourcesRaw.isEmpty
            ? nil
            : sourcesRaw.components(separatedBy: ",").filter { !$0.isEmpty }

        let request = TimeseriesRequestDTO(
            word: keyword,
            startDate: formatter.string(from: startDate),
            endDate: formatter.string(from: endDate),
            sources: enabledSources
        )

        do {
            let response = try await client.fetchTimeseries(request)
            timeseriesState = .success(response)
        } catch {
            timeseriesState = .error(error)
        }
    }
}
