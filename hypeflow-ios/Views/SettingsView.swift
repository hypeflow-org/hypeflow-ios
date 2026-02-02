import SwiftUI

struct SettingsView: View {
    @AppStorage("timeframe") private var timeframeDays = 7
    @AppStorage("enabledSourceIds") private var enabledSourceIdsRaw = ""

    @State private var sources: [SourceDTO] = []
    @State private var loadingFailed = false

    private let client: APIClientProtocol

    init(client: APIClientProtocol = APIClient()) {
        self.client = client
    }

    var body: some View {
        Form {
            Section("Timeframe") {
                Picker("Date range", selection: $timeframeDays) {
                    Text("7 days").tag(7)
                    Text("14 days").tag(14)
                    Text("30 days").tag(30)
                }
                .pickerStyle(.segmented)

                Stepper(value: $timeframeDays, in: 1...90, step: 1) {
                    Text("Custom: \(timeframeDays) days")
                }
                .font(.subheadline)
                .tint(.accentColor)
            }

            Section("Data Sources") {
                if sources.isEmpty && !loadingFailed {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if loadingFailed && sources.isEmpty {
                    Label("Could not load sources.", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sources) { source in
                        Toggle(isOn: bindingFor(source)) {
                            VStack(alignment: .leading) {
                                Text(source.title)
                                Text(source.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Backend", value: "HypeFlow API")
            }
        }
        .navigationTitle("Settings")
        .task {
            do {
                sources = try await client.fetchSources()
                loadingFailed = false
            } catch {
                loadingFailed = true
            }
        }
    }

    // MARK: - Source Toggle Binding

    private var enabledSourceIds: Set<String> {
        if enabledSourceIdsRaw.isEmpty {
            return Set(sources.filter(\.enabled).map(\.id))
        }
        return Set(enabledSourceIdsRaw.components(separatedBy: ",").filter { !$0.isEmpty })
    }

    private func bindingFor(_ source: SourceDTO) -> Binding<Bool> {
        Binding(
            get: {
                enabledSourceIds.contains(source.id)
            },
            set: { isOn in
                var current = enabledSourceIds
                if isOn {
                    current.insert(source.id)
                } else {
                    current.remove(source.id)
                }
                enabledSourceIdsRaw = current.sorted().joined(separator: ",")
            }
        )
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
