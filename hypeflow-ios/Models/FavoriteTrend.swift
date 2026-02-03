import Foundation
import SwiftData

@Model
class FavoriteTrend {
    @Attribute(.unique) var trendId: String
    var keyword: String = ""
    var title: String = ""
    @Attribute(originalName: "source") var sourceId: String
    var sourceCategory: String = "tech"
    var addedAt: Date = Date.now

    // Snapshot fields
    var snapshotDays: Int?
    var snapshotStartDate: String?
    var snapshotEndDate: String?
    var snapshotSourcesRaw: String?

    var snapshotSourcesList: [String]? {
        guard let raw = snapshotSourcesRaw, !raw.isEmpty else { return nil }
        return raw.components(separatedBy: ",")
    }

    init(trendId: String, keyword: String, title: String, sourceId: String, sourceCategory: String,
         addedAt: Date = .now, snapshotDays: Int? = nil, snapshotStartDate: String? = nil,
         snapshotEndDate: String? = nil, snapshotSourcesRaw: String? = nil) {
        self.trendId = trendId
        self.keyword = keyword
        self.title = title
        self.sourceId = sourceId
        self.sourceCategory = sourceCategory
        self.addedAt = addedAt
        self.snapshotDays = snapshotDays
        self.snapshotStartDate = snapshotStartDate
        self.snapshotEndDate = snapshotEndDate
        self.snapshotSourcesRaw = snapshotSourcesRaw
    }
}
