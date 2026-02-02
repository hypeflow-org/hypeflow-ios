import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section("Data Sources") {
                ForEach(TrendUI.SourceCategory.allCases, id: \.self) { category in
                    Label(category.displayName, systemImage: category.iconName)
                }
            }

            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Backend", value: "HypeFlow API")
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
