import Foundation

struct TimeseriesResponseDTO: Decodable {
    let word: String
    let startDate: String
    let endDate: String
    let totalMentions: Int
    let dailyStatistics: [DailyStatDTO]
    let sources: [String]
    let fromCache: Bool
    let perSource: [SourceSeriesDTO]
    let errors: [SourceErrorDTO]
}

extension TimeseriesResponseDTO {
    struct DailyStatDTO: Decodable, Identifiable {
        let date: String
        let mentions: Int

        var id: String { date }
    }

    struct SourceSeriesDTO: Decodable, Identifiable {
        let source: String
        let totalMentions: Int
        let dailyStatistics: [DailyStatDTO]

        var id: String { source }
    }

    struct SourceErrorDTO: Decodable, Identifiable {
        let source: String
        let code: String
        let message: String

        var id: String { source }
    }
}
