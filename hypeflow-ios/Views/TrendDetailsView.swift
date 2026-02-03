import SwiftUI
import SwiftData

struct TrendDetailsView: View {
    let model: TrendCardModel

    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Query private var favorites: [FavoriteTrend]
    @State private var detailsVM: TrendDetailsViewModel
    @State private var selectedSource: String? = nil
    @State private var selectedPointIndex: Int? = nil
    @State private var previousTaskId: String? = nil

    private var isFavorite: Bool { !favorites.isEmpty }

    init(model: TrendCardModel, initialTimeseries: TimeseriesResponseDTO? = nil) {
        self.model = model
        let trendId = model.id
        _favorites = Query(filter: #Predicate<FavoriteTrend> { $0.trendId == trendId })

        let snapshot: TrendDetailsViewModel.SnapshotSettings?
        if let start = model.snapshotStartDate, let end = model.snapshotEndDate {
            snapshot = .init(startDate: start, endDate: end, sources: model.snapshotSources)
        } else {
            snapshot = nil
        }

        let defaultSources = model.sources.isEmpty ? nil : model.sources.map(\.id)
        _detailsVM = State(initialValue: TrendDetailsViewModel(
            keyword: model.word,
            defaultSources: defaultSources,
            initialTimeseries: initialTimeseries,
            snapshot: snapshot
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    if let primary = model.primarySource {
                        SourceBadgeView(sourceInfo: primary)
                    }

                    Text(model.title)
                        .font(.largeTitle.bold())

                    if let date = model.date {
                        Text(date, style: .date)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else if let dateRange = model.dateRange {
                        Text(dateRange)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if detailsVM.useSnapshot {
                    Button {
                        detailsVM.switchToCurrentSettings(settings: settings)
                    } label: {
                        Label("Use current settings", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .font(.subheadline)
                }

                Divider()

                // Score section
                mentionsCard

                // All sources
                if !model.sources.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sources")
                            .font(.headline)

                        FlowLayout(spacing: 8) {
                            ForEach(model.sources) { sourceInfo in
                                SourceBadgeView(sourceInfo: sourceInfo)
                            }
                        }
                    }
                    .cardStyle()
                }

                // Sparkline section
                switch detailsVM.timeseriesState {
                case .success(let response):
                    activitySection(response)

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
                            detailsVM.reload(settings: settings)
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

                // Per Source + Daily Stats + Errors
                if case .success(let resp) = detailsVM.timeseriesState {
                    if !resp.perSource.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Per Source")
                                .font(.headline)

                            ForEach(resp.perSource) { source in
                                HStack {
                                    Text(SourceMapping.map(source.source).displayName)
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                    Text("\(source.totalMentions) mentions")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .cardStyle()
                    }

                    if !resp.dailyStatistics.isEmpty {
                        DisclosureGroup("Daily Statistics") {
                            let sorted = resp.dailyStatistics.sorted { $0.date < $1.date }
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(sorted) { stat in
                                    HStack {
                                        Text(stat.date)
                                            .font(.subheadline)
                                        Spacer()
                                        Text("\(stat.mentions)")
                                            .font(.subheadline.weight(.medium))
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                        .cardStyle()
                    }

                    if !resp.errors.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Partial Errors")
                                .font(.headline)
                                .foregroundStyle(.red)

                            ForEach(resp.errors) { err in
                                HStack {
                                    Image(systemName: "exclamationmark.circle")
                                        .foregroundStyle(.red)
                                    VStack(alignment: .leading) {
                                        Text(SourceMapping.map(err.source).displayName)
                                            .font(.subheadline.weight(.medium))
                                        Text(err.message)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .cardStyle()
                    }
                }
            }
            .padding()
        }
        .navigationTitle(model.title)
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
        .task(id: detailsVM.useSnapshot ? "snapshot" : settings.queryFingerprint) {
            let taskId = detailsVM.useSnapshot ? "snapshot" : settings.queryFingerprint
            if taskId != previousTaskId {
                selectedPointIndex = nil
                previousTaskId = taskId
            }
            detailsVM.reload(settings: settings)
        }
    }

    // MARK: - Activity Section

    @ViewBuilder
    private func activitySection(_ response: TimeseriesResponseDTO) -> some View {
        let daily = response.dailyStatistics.sorted { $0.date < $1.date }
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Activity")
                    .font(.headline)
                Spacer()
                if model.sources.count > 1 {
                    Menu {
                        Button("All sources") {
                            selectedSource = nil
                            selectedPointIndex = nil
                            detailsVM.updateSourceFilter(nil, settings: settings)
                        }
                        ForEach(model.sources) { sourceInfo in
                            Button(sourceInfo.title) {
                                selectedSource = sourceInfo.id
                                selectedPointIndex = nil
                                detailsVM.updateSourceFilter([sourceInfo.id], settings: settings)
                            }
                        }
                    } label: {
                        Label(
                            selectedSource.map { SourceMapping.map($0).displayName } ?? "Sources",
                            systemImage: "line.3.horizontal.decrease.circle"
                        )
                    }
                    .font(.subheadline)
                }
            }

            let values = daily.map { Double($0.mentions) }
            if !values.isEmpty {
                SparklineView(
                    values: values,
                    selectedIndex: selectedPointIndex,
                    onSelect: { idx in selectedPointIndex = idx }
                )
                .frame(height: 80)

                HStack {
                    if let first = daily.first {
                        Text(first.date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if let idx = selectedPointIndex,
                       idx >= 0, idx < daily.count {
                        let point = daily[idx]
                        Text("\(point.date): \(point.mentions)")
                            .font(.caption.weight(.semibold))
                    } else if let last = daily.last {
                        Text("Last: \(last.mentions)")
                            .font(.caption.weight(.semibold))
                    }
                    Spacer()
                    if let last = daily.last {
                        Text(last.date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Mentions Card

    @ViewBuilder
    private var mentionsCard: some View {
        let liveMentions: Int? = {
            if case .success(let resp) = detailsVM.timeseriesState {
                return resp.totalMentions
            }
            return nil
        }()
        let displayMentions = liveMentions ?? model.metricValue
        let dateRange: String? = {
            if case .success(let resp) = detailsVM.timeseriesState {
                return "\(resp.startDate) \u{2013} \(resp.endDate)"
            }
            return model.dateRange
        }()
        let isFromCache: Bool = {
            if case .success(let resp) = detailsVM.timeseriesState {
                return resp.fromCache
            }
            return model.fromCache
        }()

        VStack(alignment: .leading, spacing: 12) {
            Text(model.metricLabel)
                .font(.headline)

            HStack(spacing: 24) {
                StatView(
                    label: "Total",
                    value: Self.formatMentions(displayMentions),
                    icon: "chart.bar.fill"
                )

                if model.sources.count > 1 {
                    StatView(
                        label: "Sources",
                        value: "\(model.sources.count)",
                        icon: "square.stack.3d.up"
                    )
                } else if let primary = model.primarySource {
                    StatView(
                        label: "Source",
                        value: primary.title,
                        icon: primary.category.iconName
                    )
                }
            }

            if let dateRange {
                Text(dateRange)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }

            if isFromCache {
                Label("Cached result", systemImage: "bolt.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .cardStyle()
    }

    private static func formatMentions(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }

    private func toggleFavorite() {
        if let existing = favorites.first {
            modelContext.delete(existing)
        } else {
            // Try to get source info: first from model, then from timeseries response
            let sourceId: String
            let sourceCategory: String
            if let first = model.sources.first {
                sourceId = first.id
                sourceCategory = first.category.rawValue
            } else if case .success(let resp) = detailsVM.timeseriesState,
                      let firstSource = resp.perSource.first {
                sourceId = firstSource.source
                sourceCategory = SourceMapping.map(firstSource.source).category.rawValue
            } else {
                sourceId = "unknown"
                sourceCategory = "tech"
            }

            // When viewing with snapshot, preserve the snapshot settings; otherwise use current settings
            let saveDays: Int?
            let saveStart: String
            let saveEnd: String
            let saveSources: String?

            if detailsVM.useSnapshot {
                saveDays = model.snapshotDays
                saveStart = model.snapshotStartDate ?? settings.startDate
                saveEnd = model.snapshotEndDate ?? settings.endDate
                saveSources = model.snapshotSources?.joined(separator: ",")
            } else {
                saveDays = settings.useCustomDates ? nil : settings.timeframeDays
                saveStart = settings.startDate
                saveEnd = settings.endDate
                saveSources = settings.enabledSourceIds.isEmpty ? nil : settings.enabledSourceIds.joined(separator: ",")
            }

            let favorite = FavoriteTrend(
                trendId: model.id,
                keyword: model.word,
                title: model.title,
                sourceId: sourceId,
                sourceCategory: sourceCategory,
                snapshotDays: saveDays,
                snapshotStartDate: saveStart,
                snapshotEndDate: saveEnd,
                snapshotSourcesRaw: saveSources
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
        let resolved = proposal.replacingUnspecifiedDimensions(by: CGSize(width: 320, height: 0))
        let maxWidth = resolved.width
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
        TrendDetailsView(
            model: TrendCardModel(
                id: "swift", word: "swift", title: "Swift",
                sources: [SourceInfo(id: "wikipedia", title: "Wikipedia", category: .encyclopedia)],
                metricLabel: "Mentions", metricValue: 48320, totalMentions: 48320,
                date: nil, sparklineValues: nil,
                changePercent: 12.5, fromCache: false, hasErrors: false,
                dateRange: "2026-01-26 \u{2013} 2026-02-02"
            )
        )
    }
    .environment(AppSettings())
}
