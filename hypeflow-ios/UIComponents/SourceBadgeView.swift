import SwiftUI

struct SourceBadgeView: View {
    let source: String
    let category: TrendUI.SourceCategory

    var body: some View {
        Label(source, systemImage: category.iconName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor.opacity(0.12))
            .foregroundStyle(badgeColor)
            .clipShape(Capsule())
    }

    private var badgeColor: Color {
        switch category {
        case .encyclopedia: return .purple
        case .news: return .red
        case .social: return .blue
        case .tech: return .orange
        case .academic: return .green
        }
    }
}

// MARK: - View modifier variant

struct SourceBadgeModifier: ViewModifier {
    let source: String
    let category: TrendUI.SourceCategory

    func body(content: Content) -> some View {
        content.overlay(alignment: .topTrailing) {
            SourceBadgeView(source: source, category: category)
                .padding(8)
        }
    }
}

extension View {
    func sourceBadge(source: String, category: TrendUI.SourceCategory) -> some View {
        modifier(SourceBadgeModifier(source: source, category: category))
    }
}

#Preview {
    SourceBadgeView(source: "Wikipedia", category: .encyclopedia)
}
