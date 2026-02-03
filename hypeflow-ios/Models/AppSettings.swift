import Foundation
import Observation

@MainActor
@Observable
final class AppSettings {
    // MARK: - Persisted settings (synced to UserDefaults)

    var timeframeDays: Int {
        didSet { defaults.set(timeframeDays, forKey: "timeframe") }
    }
    var useCustomDates: Bool {
        didSet { defaults.set(useCustomDates, forKey: "useCustomDates") }
    }
    var customStartDateRaw: String {
        didSet { defaults.set(customStartDateRaw, forKey: "customStartDate") }
    }
    var customEndDateRaw: String {
        didSet { defaults.set(customEndDateRaw, forKey: "customEndDate") }
    }
    var enabledSourceIdsRaw: String {
        didSet { defaults.set(enabledSourceIdsRaw, forKey: "enabledSourceIds") }
    }

    // MARK: - Cached sources from server
    var availableSources: [SourceDTO] = []
    var sourcesLoaded: Bool = false
    var backendOnline: Bool? = nil

    private let defaults = UserDefaults.standard

    init() {
        let stored = defaults.integer(forKey: "timeframe")
        self.timeframeDays = stored > 0 ? stored : 7
        self.useCustomDates = defaults.bool(forKey: "useCustomDates")
        self.customStartDateRaw = defaults.string(forKey: "customStartDate") ?? ""
        self.customEndDateRaw = defaults.string(forKey: "customEndDate") ?? ""
        self.enabledSourceIdsRaw = defaults.string(forKey: "enabledSourceIds") ?? ""
    }

    // MARK: - Computed

    var enabledSourceIds: [String] {
        let parsed = enabledSourceIdsRaw
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let allEnabled = availableSources.filter(\.enabled).map(\.id)
        if parsed.isEmpty { return allEnabled }
        let validIds = Set(allEnabled)
        let filtered = parsed.filter { validIds.contains($0) }
        return filtered.isEmpty ? allEnabled : filtered
    }

    var startDate: String {
        if useCustomDates, !customStartDateRaw.isEmpty { return customStartDateRaw }
        let date = Calendar.current.date(byAdding: .day, value: -timeframeDays, to: Date())!
        return Self.dateFormatter.string(from: date)
    }

    var endDate: String {
        if useCustomDates, !customEndDateRaw.isEmpty { return customEndDateRaw }
        return Self.dateFormatter.string(from: Date())
    }

    var queryFingerprint: String {
        let base: String
        if useCustomDates {
            base = "\(customStartDateRaw)|\(customEndDateRaw)|\(enabledSourceIdsRaw)"
        } else {
            base = "\(timeframeDays)|\(enabledSourceIdsRaw)"
        }
        return "\(base)|\(sourcesLoaded)"
    }

    var isReady: Bool { sourcesLoaded }

    func makeTimeseriesRequest(word: String, sourceOverride: [String]? = nil) -> TimeseriesRequestDTO {
        TimeseriesRequestDTO(
            word: word,
            startDate: startDate,
            endDate: endDate,
            sources: sourceOverride ?? (enabledSourceIds.isEmpty ? nil : enabledSourceIds)
        )
    }

    // MARK: - Server data loading

    func loadSources(client: APIClientProtocol) async {
        do {
            availableSources = try await client.fetchSources()
            sourcesLoaded = true
        } catch {
            sourcesLoaded = false
        }
    }

    func checkHealth(client: APIClientProtocol) async {
        backendOnline = await client.checkHealth()
    }

    func reportAPIResult(error: Error?) {
        if let error {
            if case APIError.networkError = error {
                backendOnline = false
            }
        } else {
            backendOnline = true
        }
    }

    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
