import Foundation

struct TimeseriesRequestDTO: Encodable {
    let word: String
    let startDate: String
    let endDate: String
    let sources: [String]?
}
