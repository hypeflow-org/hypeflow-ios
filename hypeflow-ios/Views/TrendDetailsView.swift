import SwiftUI
import SwiftData

struct TrendDetailsView: View {
    let trend: TrendUI

    @Environment(\.modelContext) private var modelContext
    @Query private var favorites: [FavoriteTrend]
    @State private var detailsVM: TrendDetailsViewModel

    private var isFavorite: Bool { !favorites.isEmpty }

    init(trend: TrendUI, initialTimeseries: TimeseriesResponseDTO? = nil) {
        self.trend = trend
        let trendId = trend.id
        _favorites = Query(filter: #Predicate<FavoriteTrend> { $0.trendId == trendId })
        _detailsVM = State(initialValue: TrendDetailsViewModel(
            keyword: trend.keyword,
            initialTimeseries: initialTimeseries
        ))
    }

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
                            value: trend.mentionsText,
                            icon: "chart.bar.fill"
                        )

                        StatView(
                            label: "Source",
                            value: trend.sourceCategory.displayName,
                            icon: trend.sourceCategory.iconName
                        )
                    }
                }
                .cardStyle()

                if trend.sources.count > 1 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sources")
                            .font(.headline)

                        FlowLayout(spacing: 8) {
                            ForEach(trend.sources, id: \.self) { sourceId in
                                Text(sourceId.capitalized)
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(.quaternary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .cardStyle()
                }

                switch detailsVM.timeseriesState {
                case .success(let response):
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Activity")
                            .font(.headline)

                        SparklineView(
                            values: response.dailyStatistics.map { Double($0.mentions) }
                        )
                        .frame(height: 80)
                    }
                    .cardStyle()

                case .loading:
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .cardStyle()

                case .error:
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Could not load activity", systemImage: "exclamationmark.triangle")
                            .font(.headline)
                            .foregroundStyle(.red)

                        Button {
                            Task { await detailsVM.reload() }
                        } label: {
                            Label("Retry", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()

                default:
                    EmptyView()
                }


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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    toggleFavorite()
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundStyle(isFavorite ? .yellow : .secondary)
                }
            }
        }
        .task {
            await detailsVM.loadIfNeeded()
        }
    }

    private func toggleFavorite() {
        if let existing = favorites.first {
            modelContext.delete(existing)
        } else {
            let favorite = FavoriteTrend(
                trendId: trend.id,
                title: trend.title,
                source: trend.source,
                sourceCategory: trend.sourceCategory.rawValue
            )
            modelContext.insert(favorite)
        }
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

// MARK: - Flow Layout for source badges

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            guard index < result.positions.count else { break }
            let position = result.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                          proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}

#Preview {
    NavigationStack {
        TrendDetailsView(trend: TrendUI.sampleData[0])
    }
}
