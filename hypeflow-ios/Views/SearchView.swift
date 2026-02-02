import SwiftUI
import SwiftData

struct SearchView: View {
    @State private var query = ""
    @Environment(\.modelContext) private var modelContext

    private var filteredTrends: [TrendUI] {
        if query.isEmpty { return TrendUI.sampleData }
        return TrendUI.sampleData.filter {
            $0.title.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        List {
            ForEach(filteredTrends) { trend in
                NavigationLink(value: trend) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(trend.title)
                                .font(.body.weight(.medium))
                            Text(trend.source)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(trend.mentionsText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .searchable(text: $query, prompt: "Search trends")
        .onSubmit(of: .search) {
            saveSearch()
        }
        .navigationTitle("Search")
        .navigationDestination(for: TrendUI.self) { trend in
            TrendDetailsView(trend: trend)
        }
    }

    @Query(sort: \SavedSearch.createdAt, order: .reverse) private var recentSearches: [SavedSearch]

    private func saveSearch() {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
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
}
