import SwiftUI

struct SearchView: View {
    @State private var query = ""

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
        .navigationTitle("Search")
        .navigationDestination(for: TrendUI.self) { trend in
            TrendDetailsView(trend: trend)
        }
    }

}

#Preview {
    NavigationStack {
        SearchView()
    }
}
