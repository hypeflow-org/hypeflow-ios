import Foundation

@MainActor
@Observable
final class TrendDetailsViewModel {
    var timeseriesState: LoadState<TimeseriesResponseDTO> = .idle
    var useSnapshot: Bool

    private let keyword: String
    private let defaultSources: [String]?
    private let snapshot: SnapshotSettings?
    private var sourceFilter: [String]?
    private var currentTask: Task<Void, Never>?
    private var initialLoadDone: Bool = false
    private let client: APIClientProtocol

    struct SnapshotSettings {
        let startDate: String
        let endDate: String
        let sources: [String]?
    }

    init(keyword: String, defaultSources: [String]? = nil,
         initialTimeseries: TimeseriesResponseDTO? = nil,
         snapshot: SnapshotSettings? = nil, client: APIClientProtocol? = nil) {
        self.keyword = keyword
        self.defaultSources = defaultSources
        self.client = client ?? APIClient()
        self.snapshot = snapshot
        self.useSnapshot = snapshot != nil
        if let initial = initialTimeseries {
            timeseriesState = .success(initial)
        }
    }

    func reload(settings: AppSettings) {
        if !initialLoadDone, case .success = timeseriesState {
            initialLoadDone = true
            return
        }
        initialLoadDone = true

        currentTask?.cancel()
        currentTask = Task { @MainActor in
            timeseriesState = .loading
            let request: TimeseriesRequestDTO
            if useSnapshot, let snap = snapshot {
                request = TimeseriesRequestDTO(
                    word: keyword,
                    startDate: snap.startDate,
                    endDate: snap.endDate,
                    sources: sourceFilter ?? snap.sources
                )
            } else {
                let sources = sourceFilter ?? defaultSources
                request = settings.makeTimeseriesRequest(
                    word: keyword,
                    sourceOverride: sources
                )
            }

            do {
                let response = try await client.fetchTimeseries(request)
                guard !Task.isCancelled else { return }
                settings.reportAPIResult(error: nil)
                timeseriesState = .success(response)
            } catch is CancellationError {
            } catch {
                guard !Task.isCancelled else { return }
                settings.reportAPIResult(error: error)
                timeseriesState = .error(error)
            }
        }
    }

    func switchToCurrentSettings(settings: AppSettings) {
        useSnapshot = false
        reload(settings: settings)
    }

    func updateSourceFilter(_ sources: [String]?, settings: AppSettings) {
        sourceFilter = sources
        reload(settings: settings)
    }
}
