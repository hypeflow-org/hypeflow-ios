import SwiftUI

struct TrendingView: View {
    let trends: [TrendUI] = TrendUI.sampleData

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(trends) { trend in
                    NavigationLink(value: trend) {
                        TrendCardView(trend: trend)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Trending")
        .navigationDestination(for: TrendUI.self) { trend in
            TrendDetailsView(trend: trend)
        }
    }
}

#Preview {
    NavigationStack {
        TrendingView()
    }
}
