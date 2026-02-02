import Foundation
import SwiftData

@Model
class SavedSearch {
    var query: String
    var createdAt: Date

    init(query: String, createdAt: Date = .now) {
        self.query = query
        self.createdAt = createdAt
    }
}
