import Foundation

struct PopularWordDTO: Codable, Identifiable {
    let word: String
    let count: Int64

    var id: String { word }
}
