import SwiftUI

struct TrendCardView: View {
    let trend: TrendUI

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trend.title)
                        .font(.headline)

                    Text(trend.date, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                SourceBadgeView(source: trend.source, category: trend.sourceCategory)
            }

            Text(trend.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack {
                Label(formattedMentions, systemImage: "chart.bar.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                HStack(spacing: 2) {
                    Image(systemName: trend.changePercent >= 0 ? "arrow.up.right" : "arrow.down.right")
                    Text(String(format: "%.1f%%", abs(trend.changePercent)))
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(trend.changePercent >= 0 ? .green : .red)
            }
        }
        .cardStyle()
    }

    private var formattedMentions: String {
        if trend.mentions >= 1_000_000 {
            return String(format: "%.1fM", Double(trend.mentions) / 1_000_000)
        } else if trend.mentions >= 1_000 {
            return String(format: "%.1fK", Double(trend.mentions) / 1_000)
        }
        return "\(trend.mentions)"
    }
}

#Preview {
    TrendCardView(trend: TrendUI.sampleData[0])
        .padding()
}
