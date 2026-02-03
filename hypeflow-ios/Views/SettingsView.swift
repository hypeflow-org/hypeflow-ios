import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @State private var showAtLeastOneAlert = false

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section("Timeframe") {
                Picker("Date range", selection: $settings.timeframeDays) {
                    Text("7 days").tag(7)
                    Text("14 days").tag(14)
                    Text("30 days").tag(30)
                }
                .pickerStyle(.segmented)

                Toggle("Use specific dates", isOn: $settings.useCustomDates)

                if settings.useCustomDates {
                    DatePicker(
                        "Start",
                        selection: Binding(
                            get: { customStartDate },
                            set: { newDate in
                                settings.customStartDateRaw = Self.isoFormatter.string(from: newDate)
                                if customEndDate < newDate {
                                    settings.customEndDateRaw = Self.isoFormatter.string(from: newDate)
                                }
                            }
                        ),
                        displayedComponents: .date
                    )

                    DatePicker(
                        "End",
                        selection: Binding(
                            get: { customEndDate },
                            set: { newDate in
                                settings.customEndDateRaw = Self.isoFormatter.string(from: newDate)
                                if customStartDate > newDate {
                                    settings.customStartDateRaw = Self.isoFormatter.string(from: newDate)
                                }
                            }
                        ),
                        in: customStartDate...,
                        displayedComponents: .date
                    )
                }
            }

            Section("Data Sources") {
                if settings.availableSources.isEmpty && !settings.sourcesLoaded {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if settings.availableSources.isEmpty && settings.sourcesLoaded {
                    Label("No sources available.", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(settings.availableSources) { source in
                        Toggle(isOn: bindingFor(source)) {
                            VStack(alignment: .leading) {
                                Text(source.title)
                                Text(source.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if !source.enabled, let note = source.rateLimitNote {
                                    Text(note)
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                        .disabled(!source.enabled)
                        .opacity(source.enabled ? 1 : 0.5)
                    }
                }
            }

            Section("Backend Status") {
                HStack {
                    Text("Server")
                    Spacer()
                    if let online = settings.backendOnline {
                        if online {
                            Label("Online", systemImage: "circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(.green)
                        } else {
                            Label("Offline", systemImage: "circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(.red)
                        }
                    } else {
                        Text("Checking\u{2026}")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Backend", value: "HypeFlow API")
            }
        }
        .navigationTitle("Settings")
        .alert("Select at least one source", isPresented: $showAtLeastOneAlert) {
            Button("OK", role: .cancel) { }
        }
    }

    // MARK: - Source Toggle Binding

    private var enabledSourceIds: Set<String> {
        if settings.enabledSourceIdsRaw.isEmpty {
            return Set(settings.availableSources.filter(\.enabled).map(\.id))
        }
        return Set(settings.enabledSourceIdsRaw.components(separatedBy: ",").filter { !$0.isEmpty })
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
                    if current.isEmpty {
                        showAtLeastOneAlert = true
                        return
                    }
                }
                settings.enabledSourceIdsRaw = current.sorted().joined(separator: ",")
            }
        )
    }

    // MARK: - Custom dates helpers

    private var customStartDate: Date {
        dateFromRaw(settings.customStartDateRaw) ?? Date().addingTimeInterval(-7*24*3600)
    }

    private var customEndDate: Date {
        dateFromRaw(settings.customEndDateRaw) ?? Date()
    }

    private static let isoFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private func dateFromRaw(_ raw: String) -> Date? {
        guard !raw.isEmpty else { return nil }
        return Self.isoFormatter.date(from: raw)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(AppSettings())
}
