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
                Label(trend.mentionsText, systemImage: "chart.bar.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                HStack(spacing: 2) {
                    Image(systemName: trend.changeIcon)
                    Text(trend.changeText)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(trend.changePercent >= 0 ? .green : .red)
            }
        }
        .cardStyle()
    }

}

#Preview {
    TrendCardView(trend: TrendUI.sampleData[0])
        .padding()
}
