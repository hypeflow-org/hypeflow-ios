import SwiftUI

struct TrendingView: View {
    @State private var viewModel = TrendingViewModel()
    @Environment(AppSettings.self) private var settings
    @State private var selectedMode: TrendingMode = .recent

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
                                TrendCardView(model: trend)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .refreshable {
                    await viewModel.loadTrends(settings: settings, mode: selectedMode, isRefresh: true)
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
                        Task { await viewModel.loadTrends(settings: settings, mode: selectedMode) }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle("Trends")
        .safeAreaInset(edge: .top) {
            Picker("Mode", selection: $selectedMode) {
                Text("Recent").tag(TrendingMode.recent)
                Text("Popular").tag(TrendingMode.popular)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, ignoresSafeAreaEdges: [])
        }
        .navigationDestination(for: TrendCardModel.self) { model in
            TrendDetailsView(model: model)
                .id(model.id)
        }
        .task(id: "\(settings.sourcesLoaded)|\(settings.useCustomDates ? "\(settings.customStartDateRaw)|\(settings.customEndDateRaw)" : "\(settings.timeframeDays)")|\(selectedMode.rawValue)") {
            guard settings.isReady else { return }
            await viewModel.loadTrends(settings: settings, mode: selectedMode)
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.alertMessage != nil },
                set: { if !$0 { viewModel.alertMessage = nil } }
            )
        ) {
            Button("Retry") { Task { await viewModel.loadTrends(settings: settings, mode: selectedMode) } }
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
    .environment(AppSettings())
}
