import SwiftUI
import SwiftData

struct SearchView: View {
    @State private var viewModel = SearchViewModel()
    @State private var selectedPointIndex: Int?
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Query(sort: \SavedSearch.createdAt, order: .reverse) private var recentSearches: [SavedSearch]

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                idleContent

            case .loading:
                ProgressView("Searching\u{2026}")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .success(let response):
                successContent(response)

            case .empty:
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("No data found for \"\(viewModel.query)\".")
                )

            case .error:
                ContentUnavailableView {
                    Label("Search Failed", systemImage: "exclamationmark.triangle")
                } description: {
                    Text("Could not complete the search. Please try again.")
                } actions: {
                    Button("Retry") {
                        viewModel.search(settings: settings)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .animation(.default, value: viewModel.state.caseName)
        .searchable(text: $viewModel.query, prompt: "Search trends")
        .onSubmit(of: .search) {
            selectedPointIndex = nil
            viewModel.search(settings: settings)
        }
        .navigationTitle("Search")
        .safeAreaInset(edge: .top) {
            if viewModel.state.caseName != "idle" {
                controlRow
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, ignoresSafeAreaEdges: [])
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .task {
            await viewModel.loadPopular()
        }
        .onChange(of: viewModel.successCount) {
            saveSearch()
        }
        .alert(
            "Notice",
            isPresented: Binding(
                get: { viewModel.alertMessage != nil },
                set: { if !$0 { viewModel.alertMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
    }

    // MARK: - Idle Content

    @ViewBuilder
    private var idleContent: some View {
        List {
            if !recentSearches.isEmpty {
                Section("Recent") {
                    ForEach(recentSearches.prefix(10)) { search in
                        Button {
                            viewModel.query = search.query
                            viewModel.search(settings: settings)
                        } label: {
                            Label(search.query, systemImage: "clock")
                        }
                    }
                }
            }

            if !viewModel.popular.isEmpty {
                Section("Popular") {
                    ForEach(viewModel.popular) { word in
                        Button {
                            viewModel.query = word.word
                            viewModel.search(settings: settings)
                        } label: {
                            HStack {
                                Label(word.word, systemImage: "chart.line.uptrend.xyaxis")
                                Spacer()
                                Text("\(word.count)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Success Content

    @ViewBuilder
    private func successContent(_ response: TimeseriesResponseDTO) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                summaryCard(response)

                let daily = response.dailyStatistics.sorted { $0.date < $1.date }
                if !daily.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Activity")
                            .font(.headline)
                        if !response.perSource.isEmpty {
                            sourcesMenu(response: response)
                                .font(.subheadline)
                        }

                        let values = daily.map { Double($0.mentions) }
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
                                    .foregroundStyle(.primary)
                            }
                            Spacer()
                            if let last = daily.last {
                                Text(last.date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .cardStyle()
                }

                if !response.perSource.isEmpty {
                    perSourceSection(response.perSource)
                }

                if !response.errors.isEmpty {
                    errorsSection(response.errors)
                }

                if !response.dailyStatistics.isEmpty {
                    DisclosureGroup("Daily Statistics") {
                        dailyStatsSection(response.dailyStatistics.sorted { $0.date < $1.date })
                    }
                    .cardStyle()
                }
            }
            .padding()
        }
    }

    // MARK: - Sources Menu

    @ViewBuilder
    private func sourcesMenu(response: TimeseriesResponseDTO) -> some View {
        if !response.perSource.isEmpty {
            Menu {
                Button("All sources") {
                    selectedPointIndex = nil
                    viewModel.search(settings: settings)
                }
                ForEach(response.perSource) { source in
                    Button(source.source.capitalized) {
                        selectedPointIndex = nil
                        viewModel.search(settings: settings, sourceOverride: [source.source])
                    }
                }
            } label: {
                Label("Sources", systemImage: "line.3.horizontal.decrease.circle")
            }
        }
    }

    // MARK: - Summary Card

    private func summaryCard(_ response: TimeseriesResponseDTO) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(response.word.capitalized)
                .font(.title2.bold())

            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("\(response.totalMentions)")
                        .font(.headline)
                    Text("Total Mentions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 4) {
                    Text("\(response.startDate) \u{2013} \(response.endDate)")
                        .font(.headline)
                    Text("Date Range")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if response.fromCache {
                Label("Cached result", systemImage: "bolt.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Per Source

    private func perSourceSection(_ sources: [TimeseriesResponseDTO.SourceSeriesDTO]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Per Source")
                .font(.headline)

            ForEach(sources) { source in
                HStack {
                    Text(source.source.capitalized)
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

    // MARK: - Control Row

    private var controlRow: some View {
        HStack {
            Button("Start new search") {
                viewModel.resetToIdle()
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .font(.subheadline)
    }

    // MARK: - Errors

    private func errorsSection(_ errors: [TimeseriesResponseDTO.SourceErrorDTO]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Partial Errors")
                .font(.headline)
                .foregroundStyle(.red)

            ForEach(errors) { err in
                HStack {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundStyle(.red)
                    VStack(alignment: .leading) {
                        Text(err.source.capitalized)
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

    // MARK: - Daily Stats

    private func dailyStatsSection(_ stats: [TimeseriesResponseDTO.DailyStatDTO]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(stats) { stat in
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

    // MARK: - Save Search

    private func saveSearch() {
        let trimmed = viewModel.lastSearchedQuery
        guard !trimmed.isEmpty else { return }
        let lowered = trimmed.lowercased()
        guard !recentSearches.contains(where: { $0.query.lowercased() == lowered }) else { return }
        let search = SavedSearch(
            query: trimmed,
            snapshotDays: settings.useCustomDates ? nil : settings.timeframeDays,
            snapshotStartDate: settings.startDate,
            snapshotEndDate: settings.endDate,
            snapshotSourcesRaw: settings.enabledSourceIds.isEmpty ? nil : settings.enabledSourceIds.joined(separator: ",")
        )
        modelContext.insert(search)
    }
}

#Preview {
    NavigationStack {
        SearchView()
    }
    .modelContainer(for: [FavoriteTrend.self, SavedSearch.self], inMemory: true)
    .environment(AppSettings())
}
