enum TrendingMode: String, CaseIterable, Identifiable {
    case recent
    case popular

    var id: String { rawValue }
}
