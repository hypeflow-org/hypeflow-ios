import Foundation

enum SourceMapping {
    static func map(_ sourceId: String) -> (displayName: String, category: SourceCategory) {
        switch sourceId.lowercased() {
        case "wikipedia":     return ("Wikipedia", .encyclopedia)
        case "hackernews":    return ("HackerNews", .tech)
        case "stackexchange": return ("StackExchange", .tech)
        case "gdelt":         return ("GDELT", .news)
        case "newsapi":       return ("NewsAPI", .news)
        case "reddit":        return ("Reddit", .social)
        case "arxiv":         return ("arXiv", .academic)
        default:              return (sourceId.capitalized, .tech)
        }
    }
}
