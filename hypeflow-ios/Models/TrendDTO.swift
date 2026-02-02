import Foundation

struct TrendDTO: Codable {
    let word: String
    let startDate: String
    let endDate: String
    let sources: [String]
    let totalMentions: Int?
    let searchedAt: String
}

extension TrendDTO {
    static func parseDate(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()

        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) { return date }

        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: string) { return date }

        if let date = formatter.date(from: string + "Z") { return date }

        if let date = formatter.date(from: string + "T00:00:00Z") { return date }

        return nil
    }
}
