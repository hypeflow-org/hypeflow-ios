import Foundation

struct TrendUI: Identifiable, Hashable {
    let id: String
    let keyword: String
    let title: String
    let source: String
    let sourceCategory: SourceCategory
    let sources: [String]
    let mentions: Int
    var changePercent: Double
    let summary: String
    let date: Date
    var sparklineValues: [Double]? = nil

    var mentionsText: String {
        if mentions >= 1_000_000 {
            return String(format: "%.1fM", Double(mentions) / 1_000_000)
        } else if mentions >= 1_000 {
            return String(format: "%.1fK", Double(mentions) / 1_000)
        }
        return "\(mentions)"
    }

    var changeText: String {
        String(format: "%+.1f%%", changePercent)
    }

    var changeIcon: String {
        changePercent >= 0 ? "arrow.up.right" : "arrow.down.right"
    }
    

    // Hash / equality only rely on persistent id to avoid sparkline mutating identity
    static func == (lhs: TrendUI, rhs: TrendUI) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    enum SourceCategory: String, CaseIterable, Hashable {
        case encyclopedia
        case news
        case social
        case tech
        case academic

        var displayName: String {
            switch self {
            case .encyclopedia: return "Encyclopedia"
            case .news: return "News"
            case .social: return "Social"
            case .tech: return "Tech"
            case .academic: return "Academic"
            }
        }

        var iconName: String {
            switch self {
            case .encyclopedia: return "book.fill"
            case .news: return "newspaper.fill"
            case .social: return "bubble.left.and.bubble.right.fill"
            case .tech: return "chevron.left.forwardslash.chevron.right"
            case .academic: return "graduationcap.fill"
            }
        }
    }
}

// MARK: - Sample Data

extension TrendUI {
    static let sampleData: [TrendUI] = {
        let calendar = Calendar.current
        let today = Date()

        func date(daysAgo: Int) -> Date {
            calendar.date(byAdding: .day, value: -daysAgo, to: today)!
        }

        return [
            TrendUI(
                id: "wikipedia|swift",
                keyword: "swift",
                title: "Swift",
                source: "Wikipedia",
                sourceCategory: .encyclopedia,
                sources: ["wikipedia"],
                mentions: 48_320,
                changePercent: 12.5,
                summary: "Apple's programming language seeing renewed interest after WWDC announcements.",
                date: date(daysAgo: 0)
            ),
            TrendUI(
                id: "hackernews|rust",
                keyword: "rust",
                title: "Rust",
                source: "HackerNews",
                sourceCategory: .tech,
                sources: ["hackernews"],
                mentions: 3_215,
                changePercent: 8.3,
                summary: "Growing adoption in systems programming and WebAssembly toolchains.",
                date: date(daysAgo: 0)
            ),
            TrendUI(
                id: "gdelt|gpt-5",
                keyword: "gpt-5",
                title: "GPT-5",
                source: "GDELT",
                sourceCategory: .news,
                sources: ["gdelt"],
                mentions: 72_100,
                changePercent: 45.2,
                summary: "Massive media coverage following the latest model release and benchmark results.",
                date: date(daysAgo: 1)
            ),
            TrendUI(
                id: "stackexchange|kubernetes",
                keyword: "kubernetes",
                title: "Kubernetes",
                source: "StackExchange",
                sourceCategory: .tech,
                sources: ["stackexchange"],
                mentions: 1_890,
                changePercent: -3.1,
                summary: "Steady question volume around deployment and networking configurations.",
                date: date(daysAgo: 1)
            ),
            TrendUI(
                id: "arxiv|quantum-computing",
                keyword: "quantum computing",
                title: "Quantum Computing",
                source: "arXiv",
                sourceCategory: .academic,
                sources: ["arxiv"],
                mentions: 524,
                changePercent: 18.7,
                summary: "Spike in publications on error-correction and topological qubits.",
                date: date(daysAgo: 2)
            ),
            TrendUI(
                id: "reddit|bitcoin",
                keyword: "bitcoin",
                title: "Bitcoin",
                source: "Reddit",
                sourceCategory: .social,
                sources: ["reddit"],
                mentions: 15_600,
                changePercent: -7.4,
                summary: "Post-halving discussion cooling down after initial surge.",
                date: date(daysAgo: 0)
            ),
            TrendUI(
                id: "gdelt|climate-change",
                keyword: "climate change",
                title: "Climate Change",
                source: "GDELT",
                sourceCategory: .news,
                sources: ["gdelt"],
                mentions: 89_450,
                changePercent: 5.1,
                summary: "UN summit coverage driving sustained global media attention.",
                date: date(daysAgo: 3)
            ),
            TrendUI(
                id: "hackernews|react-native",
                keyword: "react native",
                title: "React Native",
                source: "HackerNews",
                sourceCategory: .tech,
                sources: ["hackernews"],
                mentions: 1_340,
                changePercent: -12.0,
                summary: "Declining mentions as developers explore alternative cross-platform solutions.",
                date: date(daysAgo: 2)
            ),
            TrendUI(
                id: "arxiv|crispr",
                keyword: "crispr",
                title: "CRISPR",
                source: "arXiv",
                sourceCategory: .academic,
                sources: ["arxiv"],
                mentions: 312,
                changePercent: 22.8,
                summary: "New therapeutic applications published in gene therapy research.",
                date: date(daysAgo: 4)
            ),
            TrendUI(
                id: "wikipedia|tesla",
                keyword: "tesla",
                title: "Tesla",
                source: "Wikipedia",
                sourceCategory: .encyclopedia,
                sources: ["wikipedia"],
                mentions: 62_800,
                changePercent: 9.6,
                summary: "Page views up following earnings report and new vehicle announcements.",
                date: date(daysAgo: 1)
            ),
            TrendUI(
                id: "stackexchange|swiftui",
                keyword: "swiftui",
                title: "SwiftUI",
                source: "StackExchange",
                sourceCategory: .tech,
                sources: ["stackexchange"],
                mentions: 870,
                changePercent: 31.2,
                summary: "Questions surging around new declarative UI APIs and navigation patterns.",
                date: date(daysAgo: 0)
            ),
            TrendUI(
                id: "gdelt|ukraine",
                keyword: "ukraine",
                title: "Ukraine",
                source: "GDELT",
                sourceCategory: .news,
                sources: ["gdelt"],
                mentions: 134_200,
                changePercent: -2.3,
                summary: "Ongoing coverage with slight decrease from previous week's peak.",
                date: date(daysAgo: 1)
            ),
            TrendUI(
                id: "arxiv|llm-fine-tuning",
                keyword: "llm fine-tuning",
                title: "LLM Fine-tuning",
                source: "arXiv",
                sourceCategory: .academic,
                sources: ["arxiv"],
                mentions: 289,
                changePercent: 67.4,
                summary: "Rapid growth in papers exploring efficient adaptation techniques.",
                date: date(daysAgo: 3)
            ),
        ]
    }()
}
