import Foundation

struct TrendCardModel: Identifiable, Hashable {
    let id: String
    let word: String
    let title: String
    let sources: [SourceInfo]
    let metricLabel: String
    let metricValue: Int
    let totalMentions: Int
    let date: Date?
    var sparklineValues: [Double]?
    var changePercent: Double?
    let fromCache: Bool
    let hasErrors: Bool
    var dateRange: String?

    var snapshotDays: Int?
    var snapshotStartDate: String?
    var snapshotEndDate: String?
    var snapshotSources: [String]?

    var fingerprint: String {
        "\(metricValue)|\(totalMentions)|\(changePercent ?? 0)|\(fromCache)|\(hasErrors)|\(sparklineValues?.count ?? 0)|\(dateRange ?? "")"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(fingerprint)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.fingerprint == rhs.fingerprint
    }
}

struct SourceInfo: Identifiable, Hashable {
    let id: String
    let title: String
    let category: SourceCategory
}

enum SourceCategory: String, CaseIterable, Hashable {
    case encyclopedia, news, social, tech, academic

    init(fromString s: String) {
        self = SourceCategory(rawValue: s.lowercased()) ?? .tech
    }

    var displayName: String { rawValue.capitalized }
    var iconName: String {
        switch self {
        case .encyclopedia: "book.fill"
        case .news: "newspaper.fill"
        case .social: "bubble.left.and.bubble.right.fill"
        case .tech: "chevron.left.forwardslash.chevron.right"
        case .academic: "graduationcap.fill"
        }
    }
}

// MARK: - Conversions

extension TrendCardModel {
    static func from(_ item: TrendItemDTO) -> TrendCardModel {
        let sourceInfos = item.sources.map {
            SourceInfo(id: $0.id, title: $0.title, category: SourceCategory(fromString: $0.category))
        }
        let label = item.metric.type == "searches" ? "Searches" : "Mentions"
        let sparkline = item.daily
            .sorted { $0.date < $1.date }
            .map { Double($0.mentions) }

        return TrendCardModel(
            id: item.id,
            word: item.word,
            title: item.word.capitalized,
            sources: sourceInfos,
            metricLabel: label,
            metricValue: item.metric.value,
            totalMentions: item.totalMentions,
            date: nil,
            sparklineValues: sparkline.isEmpty ? nil : sparkline,
            changePercent: item.changePercent,
            fromCache: item.fromCache,
            hasErrors: !item.errors.isEmpty,
            dateRange: nil
        )
    }

    static func from(_ fav: FavoriteTrend) -> TrendCardModel {
        let sources: [SourceInfo]
        if fav.sourceId.lowercased() != "unknown" && !fav.sourceId.isEmpty {
            let mapped = SourceMapping.map(fav.sourceId)
            sources = [SourceInfo(id: fav.sourceId, title: mapped.displayName, category: mapped.category)]
        } else {
            sources = []
        }
        return TrendCardModel(
            id: fav.trendId, word: fav.keyword, title: fav.title,
            sources: sources, metricLabel: "Mentions", metricValue: 0,
            totalMentions: 0, date: fav.addedAt,
            sparklineValues: nil, changePercent: nil,
            fromCache: false, hasErrors: false, dateRange: nil,
            snapshotDays: fav.snapshotDays,
            snapshotStartDate: fav.snapshotStartDate,
            snapshotEndDate: fav.snapshotEndDate,
            snapshotSources: fav.snapshotSourcesList
        )
    }

    static func from(_ search: SavedSearch) -> TrendCardModel {
        TrendCardModel(
            id: search.query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            word: search.query, title: search.query.capitalized,
            sources: [], metricLabel: "Mentions", metricValue: 0,
            totalMentions: 0, date: search.createdAt,
            sparklineValues: nil, changePercent: nil,
            fromCache: false, hasErrors: false, dateRange: nil,
            snapshotDays: search.snapshotDays,
            snapshotStartDate: search.snapshotStartDate,
            snapshotEndDate: search.snapshotEndDate,
            snapshotSources: search.snapshotSourcesList
        )
    }
}

// MARK: - Computed helpers

extension TrendCardModel {
    var primarySource: SourceInfo? { sources.first }

    var metricText: String {
        if metricValue >= 1_000_000 { return String(format: "%.1fM", Double(metricValue) / 1_000_000) }
        if metricValue >= 1_000 { return String(format: "%.1fK", Double(metricValue) / 1_000) }
        return "\(metricValue)"
    }

    var changeText: String {
        guard let changePercent else { return "\u{2014}" }
        return String(format: "%+.1f%%", changePercent)
    }

    var changeIcon: String? {
        guard let changePercent else { return nil }
        return changePercent >= 0 ? "arrow.up.right" : "arrow.down.right"
    }
}
