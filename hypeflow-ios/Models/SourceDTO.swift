import Foundation

struct SourceDTO: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let category: String
    let unit: String
    let maxRangeDays: Int?
    let rateLimitNote: String?
    let docsUrl: String?
    let defaultWeight: Double
    let enabled: Bool
}
