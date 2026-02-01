import Foundation

struct TrendUI: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let source: String
    let sourceCategory: SourceCategory
    let mentions: Int
    let changePercent: Double
    let summary: String
    let date: Date

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
                title: "Swift",
                source: "Wikipedia",
                sourceCategory: .encyclopedia,
                mentions: 48_320,
                changePercent: 12.5,
                summary: "Apple's programming language seeing renewed interest after WWDC announcements.",
                date: date(daysAgo: 0)
            ),
            TrendUI(
                title: "Rust",
                source: "HackerNews",
                sourceCategory: .tech,
                mentions: 3_215,
                changePercent: 8.3,
                summary: "Growing adoption in systems programming and WebAssembly toolchains.",
                date: date(daysAgo: 0)
            ),
            TrendUI(
                title: "GPT-5",
                source: "GDELT",
                sourceCategory: .news,
                mentions: 72_100,
                changePercent: 45.2,
                summary: "Massive media coverage following the latest model release and benchmark results.",
                date: date(daysAgo: 1)
            ),
            TrendUI(
                title: "Kubernetes",
                source: "StackExchange",
                sourceCategory: .tech,
                mentions: 1_890,
                changePercent: -3.1,
                summary: "Steady question volume around deployment and networking configurations.",
                date: date(daysAgo: 1)
            ),
            TrendUI(
                title: "Quantum Computing",
                source: "arXiv",
                sourceCategory: .academic,
                mentions: 524,
                changePercent: 18.7,
                summary: "Spike in publications on error-correction and topological qubits.",
                date: date(daysAgo: 2)
            ),
            TrendUI(
                title: "Bitcoin",
                source: "Reddit",
                sourceCategory: .social,
                mentions: 15_600,
                changePercent: -7.4,
                summary: "Post-halving discussion cooling down after initial surge.",
                date: date(daysAgo: 0)
            ),
            TrendUI(
                title: "Climate Change",
                source: "GDELT",
                sourceCategory: .news,
                mentions: 89_450,
                changePercent: 5.1,
                summary: "UN summit coverage driving sustained global media attention.",
                date: date(daysAgo: 3)
            ),
            TrendUI(
                title: "React Native",
                source: "HackerNews",
                sourceCategory: .tech,
                mentions: 1_340,
                changePercent: -12.0,
                summary: "Declining mentions as developers explore alternative cross-platform solutions.",
                date: date(daysAgo: 2)
            ),
            TrendUI(
                title: "CRISPR",
                source: "arXiv",
                sourceCategory: .academic,
                mentions: 312,
                changePercent: 22.8,
                summary: "New therapeutic applications published in gene therapy research.",
                date: date(daysAgo: 4)
            ),
            TrendUI(
                title: "Tesla",
                source: "Wikipedia",
                sourceCategory: .encyclopedia,
                mentions: 62_800,
                changePercent: 9.6,
                summary: "Page views up following earnings report and new vehicle announcements.",
                date: date(daysAgo: 1)
            ),
            TrendUI(
                title: "SwiftUI",
                source: "StackExchange",
                sourceCategory: .tech,
                mentions: 870,
                changePercent: 31.2,
                summary: "Questions surging around new declarative UI APIs and navigation patterns.",
                date: date(daysAgo: 0)
            ),
            TrendUI(
                title: "Ukraine",
                source: "GDELT",
                sourceCategory: .news,
                mentions: 134_200,
                changePercent: -2.3,
                summary: "Ongoing coverage with slight decrease from previous week's peak.",
                date: date(daysAgo: 1)
            ),
            TrendUI(
                title: "LLM Fine-tuning",
                source: "arXiv",
                sourceCategory: .academic,
                mentions: 289,
                changePercent: 67.4,
                summary: "Rapid growth in papers exploring efficient adaptation techniques.",
                date: date(daysAgo: 3)
            ),
        ]
    }()
}
