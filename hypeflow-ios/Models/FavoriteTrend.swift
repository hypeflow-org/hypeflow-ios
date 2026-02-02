import Foundation
import SwiftData

@Model
class FavoriteTrend {
    @Attribute(.unique) var trendId: String
    var title: String
    var source: String
    var sourceCategory: String
    var addedAt: Date

    init(trendId: String, title: String, source: String, sourceCategory: String, addedAt: Date = .now) {
        self.trendId = trendId
        self.title = title
        self.source = source
        self.sourceCategory = sourceCategory
        self.addedAt = addedAt
    }
}
