import Foundation

struct TrendsResponseDTO: Decodable {
    let mode: String
    let startDate: String
    let endDate: String
    let sources: [String]
    let items: [TrendItemDTO]
}

struct TrendItemDTO: Decodable, Identifiable {
    let id: String
    let word: String
    let sources: [SourceInfoDTO]
    let metric: MetricDTO
    let totalMentions: Int
    let daily: [DailyStatDTO]
    let changePercent: Double?
    let fromCache: Bool
    let errors: [SourceErrorDTO]

    struct SourceInfoDTO: Decodable, Hashable {
        let id: String
        let title: String
        let category: String
    }

    struct MetricDTO: Decodable {
        let type: String
        let value: Int
    }

    struct DailyStatDTO: Decodable, Identifiable {
        let date: String
        let mentions: Int
        var id: String { date }
    }

    struct SourceErrorDTO: Decodable, Identifiable {
        let source: String
        let code: String
        let message: String
        var id: String { "\(source)_\(code)" }
    }
}
