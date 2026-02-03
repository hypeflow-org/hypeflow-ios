import SwiftUI

enum TrendCardStyle {
    case detailed
    case compact
}

struct TrendCardView: View {
    let model: TrendCardModel
    var style: TrendCardStyle = .detailed

    var body: some View {
        VStack(alignment: .leading, spacing: style == .compact ? 6 : 10) {
            headerRow

            if style == .detailed {
                if let values = model.sparklineValues, !values.isEmpty {
                    SparklineView(values: values)
                        .frame(height: 36)
                }
            }

            footerRow
        }
        .cardStyle()
    }

    // MARK: - Header

    @ViewBuilder
    private var headerRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.title)
                    .font(.headline)

                if let date = model.date {
                    Text(date, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else if let dateRange = model.dateRange {
                    Text(dateRange)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if model.sources.count > 1 {
                Label("\(model.sources.count) sources", systemImage: "square.stack.3d.up")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary)
                    .clipShape(Capsule())
            } else if let primary = model.primarySource {
                SourceBadgeView(sourceInfo: primary)
            }
        }
    }

    // MARK: - Footer

    @ViewBuilder
    private var footerRow: some View {
        let showMetric = style == .detailed || model.metricValue > 0
        let hasChange = model.changeIcon != nil && model.changePercent != nil
        let hasAnything = showMetric || hasChange || model.fromCache || model.hasErrors

        if hasAnything {
            HStack {
                if showMetric {
                    Label("\(model.metricLabel): \(model.metricText)", systemImage: "chart.bar.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if model.fromCache {
                    Label("Cached", systemImage: "bolt.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }

                if model.hasErrors {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }

                if let icon = model.changeIcon, let change = model.changePercent {
                    HStack(spacing: 2) {
                        Image(systemName: icon)
                        Text(String(format: "%+.1f%%", change))
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(change >= 0 ? .green : .red)
                }
            }
        }
    }
}

#Preview {
    VStack {
        TrendCardView(
            model: TrendCardModel(
                id: "swift", word: "swift", title: "Swift",
                sources: [SourceInfo(id: "wikipedia", title: "Wikipedia", category: .encyclopedia)],
                metricLabel: "Mentions", metricValue: 48320, totalMentions: 48320,
                date: nil, sparklineValues: [10, 20, 15, 30, 25, 35, 40],
                changePercent: 12.5, fromCache: false, hasErrors: false,
                dateRange: "2026-01-26 \u{2013} 2026-02-02"
            ),
            style: .detailed
        )
        TrendCardView(
            model: TrendCardModel(
                id: "rust", word: "rust", title: "Rust",
                sources: [SourceInfo(id: "hackernews", title: "HackerNews", category: .tech)],
                metricLabel: "Mentions", metricValue: 3215, totalMentions: 3215,
                date: Date(), sparklineValues: nil,
                changePercent: nil, fromCache: true, hasErrors: false,
                dateRange: nil
            ),
            style: .compact
        )
    }
    .padding()
}
