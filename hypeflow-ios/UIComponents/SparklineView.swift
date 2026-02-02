import SwiftUI

struct SparklineView: View {
    let values: [Double]
    var lineColor: Color = .blue

    @State private var trimEnd: CGFloat = 0

    var body: some View {
        if values.count < 2 {
            EmptyView()
        } else {
            GeometryReader { geo in
                let normalized = normalizedValues()
                let points = points(for: normalized, in: geo.size)

                ZStack {
                    Path { path in
                        path.move(to: CGPoint(x: points[0].x, y: geo.size.height))
                        for point in points {
                            path.addLine(to: point)
                        }
                        path.addLine(to: CGPoint(x: points.last!.x, y: geo.size.height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [lineColor.opacity(0.3), lineColor.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .opacity(trimEnd)

                    Path { path in
                        path.move(to: points[0])
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .trim(from: 0, to: trimEnd)
                    .stroke(lineColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    trimEnd = 1
                }
            }
        }
    }

    private func normalizedValues() -> [Double] {
        guard let minVal = values.min(), let maxVal = values.max() else {
            return values.map { _ in 0.5 }
        }
        let range = maxVal - minVal
        if range == 0 {
            return values.map { _ in 0.5 }
        }
        return values.map { ($0 - minVal) / range }
    }

    private func points(for normalized: [Double], in size: CGSize) -> [CGPoint] {
        let count = normalized.count
        guard count > 1 else { return [] }
        let stepX = size.width / CGFloat(count - 1)
        return normalized.enumerated().map { index, value in
            CGPoint(
                x: stepX * CGFloat(index),
                y: size.height * (1 - CGFloat(value))
            )
        }
    }
}

#Preview {
    SparklineView(values: [10, 25, 15, 40, 30, 50, 45, 60])
        .frame(height: 80)
        .padding()
}
