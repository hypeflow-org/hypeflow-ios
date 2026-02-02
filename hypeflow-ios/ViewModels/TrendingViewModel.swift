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
            let merged = mergeDuplicates(dtos)
            var trends = merged.map { $0.toTrendUI() }
            trends = await enrichWithTimeseries(trends)
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

    // MARK: - Helpers

    private func mergeDuplicates(_ dtos: [TrendDTO]) -> [TrendDTO] {
        var map: [String: TrendDTO] = [:]

        for dto in dtos {
            let key = "\(dto.word.lowercased())|\(dto.startDate)|\(dto.endDate)"
            if var existing = map[key] {
                let mergedSources = Array(Set(existing.sources + dto.sources))
                let mergedMentions = (existing.totalMentions ?? 0) + (dto.totalMentions ?? 0)
                let newerSearchedAt = dto.searchedAt > existing.searchedAt ? dto.searchedAt : existing.searchedAt

                existing = TrendDTO(
                    word: existing.word,
                    startDate: existing.startDate,
                    endDate: existing.endDate,
                    sources: mergedSources,
                    totalMentions: mergedMentions == 0 ? existing.totalMentions : mergedMentions,
                    searchedAt: newerSearchedAt
                )
                map[key] = existing
            } else {
                map[key] = dto
            }
        }

        return Array(map.values).sorted { $0.searchedAt > $1.searchedAt }
    }

    private func enrichWithTimeseries(_ trends: [TrendUI]) async -> [TrendUI] {
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
            : sourcesRaw.split(separator: ",").map(String.init)

        let slice = trends.prefix(6) // keep lightweight
        var timeseriesMap: [String: TimeseriesResponseDTO] = [:]

        await withTaskGroup(of: (String, TimeseriesResponseDTO?).self) { group in
            for trend in slice {
                group.addTask {
                    let request = TimeseriesRequestDTO(
                        word: trend.keyword,
                        startDate: formatter.string(from: startDate),
                        endDate: formatter.string(from: endDate),
                        sources: enabledSources
                    )
                    do {
                        let response = try await self.client.fetchTimeseries(request)
                        return (trend.id, response)
                    } catch {
                        return (trend.id, nil)
                    }
                }
            }

            for await result in group {
                if let dto = result.1 {
                    timeseriesMap[result.0] = dto
                }
            }
        }

        return trends.map { trend in
            guard let ts = timeseriesMap[trend.id] else { return trend }
            var updated = trend
            let values = ts.dailyStatistics.map { Double($0.mentions) }
            updated.sparklineValues = values
            if let first = values.first, let last = values.last, first != 0 {
                updated.changePercent = ((last - first) / first) * 100
            }
            return updated
        }
    }
}
