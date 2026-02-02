import Foundation

struct TrendDTO: Codable {
    let word: String
    let startDate: String
    let endDate: String
    let sources: [String]
    let totalMentions: Int?
    let searchedAt: String
}

// MARK: - Mapping to TrendUI

extension TrendDTO {
    func toTrendUI() -> TrendUI {
        let primarySource = sources.first ?? "unknown"
        let (displayName, category) = Self.mapSource(primarySource)
        let parsedDate = Self.parseDate(searchedAt) ?? Date()
        let idTail = searchedAt.isEmpty ? UUID().uuidString : searchedAt

        return TrendUI(
            id: "\(primarySource)|\(word)|\(startDate)|\(endDate)|\(idTail)",
            keyword: word,
            title: word.capitalized,
            source: displayName,
            sourceCategory: category,
            sources: sources,
            mentions: totalMentions ?? 0,
            changePercent: 0,
            summary: Self.buildSummary(startDate: startDate, endDate: endDate, sources: sources),
            date: parsedDate
        )
    }

    private static func mapSource(_ sourceId: String) -> (String, TrendUI.SourceCategory) {
        switch sourceId.lowercased() {
        case "wikipedia":     return ("Wikipedia", .encyclopedia)
        case "hackernews":    return ("HackerNews", .tech)
        case "stackexchange": return ("StackExchange", .tech)
        case "gdelt":         return ("GDELT", .news)
        case "newsapi":       return ("NewsAPI", .news)
        case "reddit":        return ("Reddit", .social)
        case "arxiv":         return ("arXiv", .academic)
        default:              return (sourceId.capitalized, .tech)
        }
    }

    private static func parseDate(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()

        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) { return date }

        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: string) { return date }

        if let date = formatter.date(from: string + "Z") { return date }

        if let date = formatter.date(from: string + "T00:00:00Z") { return date }

        return nil
    }

    private static func buildSummary(startDate: String, endDate: String, sources: [String]) -> String {
        let sourceList = sources.joined(separator: ", ")

        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none

        let start = parseDate(startDate)
        let end = parseDate(endDate)

        let dateRange: String
        if let start, let end {
            dateRange = "\(fmt.string(from: start)) \u{2013} \(fmt.string(from: end))"
        } else {
            dateRange = "\(startDate) \u{2013} \(endDate)"
        }

        return "Tracked \(dateRange) across \(sourceList)."
    }
}
