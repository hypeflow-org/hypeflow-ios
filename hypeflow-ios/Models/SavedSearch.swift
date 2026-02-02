import Foundation
import SwiftData

@Model
class SavedSearch {
    var query: String
    var createdAt: Date

    var snapshotDays: Int?
    var snapshotStartDate: String?
    var snapshotEndDate: String?
    var snapshotSourcesRaw: String?

    var snapshotSourcesList: [String]? {
        guard let raw = snapshotSourcesRaw, !raw.isEmpty else { return nil }
        return raw.components(separatedBy: ",")
    }

    init(query: String, createdAt: Date = .now, snapshotDays: Int? = nil,
         snapshotStartDate: String? = nil, snapshotEndDate: String? = nil,
         snapshotSourcesRaw: String? = nil) {
        self.query = query
        self.createdAt = createdAt
        self.snapshotDays = snapshotDays
        self.snapshotStartDate = snapshotStartDate
        self.snapshotEndDate = snapshotEndDate
        self.snapshotSourcesRaw = snapshotSourcesRaw
    }
}
