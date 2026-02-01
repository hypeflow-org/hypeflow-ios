import SwiftUI

struct SavedView: View {
    var body: some View {
        ContentUnavailableView(
            "No Saved Trends",
            systemImage: "bookmark",
            description: Text("Trends you save will appear here.")
        )
        .navigationTitle("Saved")
    }
}

#Preview {
    NavigationStack {
        SavedView()
    }
}
