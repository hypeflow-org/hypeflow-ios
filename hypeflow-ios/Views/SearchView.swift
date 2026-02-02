import SwiftUI
import SwiftData

struct SearchView: View {
    @State private var viewModel = SearchViewModel()
    @Environment(\.modelContext) private var modelContext
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
                        Task { await viewModel.search() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .animation(.default, value: viewModel.state.caseName)
        .searchable(text: $viewModel.query, prompt: "Search trends")
        .onSubmit(of: .search) {
            Task { await viewModel.search() }
        }
        .navigationTitle("Search")
        .toolbar {
            if viewModel.state.caseName != "idle" {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New Search") {
                        viewModel.resetToIdle()
                    }
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
                            Task { await viewModel.search() }
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
                            Task { await viewModel.search() }
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

                if !response.perSource.isEmpty {
                    perSourceSection(response.perSource)
                }

                if !response.errors.isEmpty {
                    errorsSection(response.errors)
                }

                if !response.dailyStatistics.isEmpty {
                    dailyStatsSection(response.dailyStatistics)
                }
            }
            .padding()
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily Statistics")
                .font(.headline)

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
        .cardStyle()
    }

    // MARK: - Save Search

    private func saveSearch() {
        let trimmed = viewModel.lastSearchedQuery
        guard !trimmed.isEmpty else { return }
        guard recentSearches.first?.query != trimmed else { return }
        let search = SavedSearch(query: trimmed)
        modelContext.insert(search)
    }
}

#Preview {
    NavigationStack {
        SearchView()
    }
    .modelContainer(for: [FavoriteTrend.self, SavedSearch.self], inMemory: true)
}
