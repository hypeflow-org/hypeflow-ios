import SwiftUI

struct TrendingView: View {
    @State private var viewModel = TrendingViewModel()

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView("Loading trends\u{2026}")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .success(let trends):
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
                .refreshable {
                    await viewModel.loadTrends(isRefresh: true)
                }

            case .empty:
                ContentUnavailableView(
                    "No Trends",
                    systemImage: "chart.line.downtrend.xyaxis",
                    description: Text("No trending data available. Pull down to refresh.")
                )

            case .error:
                ContentUnavailableView {
                    Label("Something Went Wrong", systemImage: "exclamationmark.triangle")
                } description: {
                    Text("Could not load trends. Please try again.")
                } actions: {
                    Button("Retry") {
                        Task { await viewModel.loadTrends() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle("Trending")
        .navigationDestination(for: TrendUI.self) { trend in
            TrendDetailsView(trend: trend)
        }
        .task {
            if case .idle = viewModel.state {
                await viewModel.loadTrends()
            }
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.alertMessage != nil },
                set: { if !$0 { viewModel.alertMessage = nil } }
            )
        ) {
            Button("Retry") { Task { await viewModel.loadTrends() } }
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
    }
}

#Preview {
    NavigationStack {
        TrendingView()
    }
}
