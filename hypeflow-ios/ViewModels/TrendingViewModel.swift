import Foundation

@MainActor
@Observable
final class TrendingViewModel {
    var state: LoadState<[TrendCardModel]> = .idle
    var alertMessage: String?
    var mode: TrendingMode = .recent

    private let client: APIClientProtocol

    init(client: APIClientProtocol? = nil) {
        self.client = client ?? APIClient()
    }

    func loadTrends(settings: AppSettings, mode: TrendingMode? = nil, isRefresh: Bool = false) async {
        if let mode { self.mode = mode }
        if !isRefresh { state = .loading }

        do {
            let response = try await client.fetchTrends(
                mode: self.mode.rawValue,
                limit: 15,
                days: settings.useCustomDates ? nil : settings.timeframeDays,
                startDate: settings.useCustomDates ? settings.startDate : nil,
                endDate: settings.useCustomDates ? settings.endDate : nil,
                sources: nil
            )

            guard !Task.isCancelled else { return }
            settings.reportAPIResult(error: nil)

            let range = "\(response.startDate) \u{2013} \(response.endDate)"
            var seen = Set<String>()
            let models = response.items.compactMap { item -> TrendCardModel? in
                guard seen.insert(item.id).inserted else { return nil }
                var m = TrendCardModel.from(item)
                m.dateRange = range
                return m
            }
            state = models.isEmpty ? .empty : .success(models)
        } catch is CancellationError {
        } catch {
            guard !Task.isCancelled else { return }
            settings.reportAPIResult(error: error)
            alertMessage = (error as? LocalizedError)?.errorDescription
                ?? error.localizedDescription

            if isRefresh, case .success = state {
                return
            }
            state = .error(error)
        }
    }
}
