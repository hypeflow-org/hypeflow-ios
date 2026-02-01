import SwiftUI

struct TrendDetailsView: View {
    let trend: TrendUI

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    SourceBadgeView(source: trend.source, category: trend.sourceCategory)

                    Text(trend.title)
                        .font(.largeTitle.bold())

                    Text(trend.date, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // Score section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Mentions")
                        .font(.headline)

                    HStack(spacing: 24) {
                        StatView(
                            label: "Total",
                            value: formattedMentions,
                            icon: "chart.bar.fill"
                        )

                        StatView(
                            label: "Change",
                            value: String(format: "%+.1f%%", trend.changePercent),
                            icon: trend.changePercent >= 0 ? "arrow.up.right" : "arrow.down.right",
                            valueColor: trend.changePercent >= 0 ? .green : .red
                        )

                        StatView(
                            label: "Source",
                            value: trend.sourceCategory.displayName,
                            icon: trend.sourceCategory.iconName
                        )
                    }
                }
                .cardStyle()

                // Summary section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Summary")
                        .font(.headline)

                    Text(trend.summary)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .cardStyle()
            }
            .padding()
        }
        .navigationTitle(trend.title)
        .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Stat subview

private struct StatView: View {
    let label: String
    let value: String
    let icon: String
    var valueColor: Color = .primary

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .foregroundStyle(valueColor)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        TrendDetailsView(trend: TrendUI.sampleData[0])
    }
}
