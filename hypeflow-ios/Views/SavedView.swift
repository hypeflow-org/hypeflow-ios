import SwiftUI
import SwiftData

struct SavedView: View {
    enum Segment: String, CaseIterable {
        case favorites = "Favorites"
        case history = "History"
    }

    @State private var selectedSegment: Segment = .favorites
    @State private var showClearAlert = false

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FavoriteTrend.addedAt, order: .reverse) private var favorites: [FavoriteTrend]
    @Query(sort: \SavedSearch.createdAt, order: .reverse) private var searches: [SavedSearch]

    var body: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $selectedSegment) {
                ForEach(Segment.allCases, id: \.self) { segment in
                    Text(segment.rawValue).tag(segment)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            Group {
                switch selectedSegment {
                case .favorites:
                    favoritesSection
                case .history:
                    historySection
                }
            }
        }
        .navigationTitle("Saved")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Clear All", role: .destructive) {
                    showClearAlert = true
                }
                .disabled(activeListIsEmpty)
            }
        }
        .alert("Clear All", isPresented: $showClearAlert) {
            Button("Clear All", role: .destructive) {
                clearAll()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete all \(selectedSegment.rawValue.lowercased())?")
        }
    }

    // MARK: - Favorites

    @ViewBuilder
    private var favoritesSection: some View {
        if favorites.isEmpty {
            ContentUnavailableView(
                "No Favorites",
                systemImage: "star",
                description: Text("Trends you favorite will appear here.")
            )
        } else {
            List {
                ForEach(favorites) { favorite in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(favorite.title)
                                .font(.body.weight(.medium))
                            if let category = TrendUI.SourceCategory(rawValue: favorite.sourceCategory) {
                                SourceBadgeView(source: favorite.source, category: category)
                            } else {
                                Text(favorite.source)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Text(favorite.addedAt, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete(perform: deleteFavorites)
            }
        }
    }

    // MARK: - History

    @ViewBuilder
    private var historySection: some View {
        if searches.isEmpty {
            ContentUnavailableView(
                "No Search History",
                systemImage: "clock",
                description: Text("Your search history will appear here.")
            )
        } else {
            List {
                ForEach(searches) { search in
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)

                        Text(search.query)
                            .font(.body)

                        Spacer()

                        Text(search.createdAt, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete(perform: deleteSearches)
            }
        }
    }

    // MARK: - Helpers

    private var activeListIsEmpty: Bool {
        switch selectedSegment {
        case .favorites: return favorites.isEmpty
        case .history: return searches.isEmpty
        }
    }

    private func deleteFavorites(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(favorites[index])
        }
    }

    private func deleteSearches(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(searches[index])
        }
    }

    private func clearAll() {
        switch selectedSegment {
        case .favorites:
            favorites.forEach { modelContext.delete($0) }
        case .history:
            searches.forEach { modelContext.delete($0) }
        }
    }
}

#Preview {
    NavigationStack {
        SavedView()
    }
    .modelContainer(for: [FavoriteTrend.self, SavedSearch.self], inMemory: true)
}
