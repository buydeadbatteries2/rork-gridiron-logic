import SwiftUI

/// Draws a receiver's route as a smoothed polyline with an arrowhead.
/// Points are normalized (0...1) in field space.
nonisolated struct RouteArrow: View {
    let route: OffensiveRoute
    let fieldSize: CGSize

    private var resolvedPoints: [CGPoint] {
        route.points.map {
            CGPoint(x: $0.x * fieldSize.width, y: $0.y * fieldSize.height)
        }
    }

    var body: some View {
        ZStack {
            RouteLine(points: resolvedPoints)
                .stroke(
                    route.kind.color,
                    style: StrokeStyle(lineWidth: 3.2, lineCap: .round, lineJoin: .round)
                )
                .shadow(color: route.kind.color.opacity(0.6), radius: 4)

            if let head = arrowHead {
                head
                    .fill(route.kind.color)
                    .shadow(color: route.kind.color.opacity(0.6), radius: 4)
            }
        }
        .allowsHitTesting(false)
    }

    /// Triangular arrowhead oriented along the final route segment.
    private var arrowHead: Path? {
        let points = resolvedPoints
        guard points.count >= 2 else { return nil }
        let tip = points[points.count - 1]
        let previous = points[points.count - 2]

        let dx = tip.x - previous.x
        let dy = tip.y - previous.y
        let length = max(0.001, sqrt(dx * dx + dy * dy))
        let ux = dx / length
        let uy = dy / length
        let size: CGFloat = 10

        let base = CGPoint(x: tip.x - ux * size, y: tip.y - uy * size)
        let left = CGPoint(x: base.x - uy * size * 0.5, y: base.y + ux * size * 0.5)
        let right = CGPoint(x: base.x + uy * size * 0.5, y: base.y - ux * size * 0.5)

        var path = Path()
        path.move(to: tip)
        path.addLine(to: left)
        path.addLine(to: right)
        path.closeSubpath()
        return path
    }
}

/// Smoothed line through route waypoints.
nonisolated struct RouteLine: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)

        guard points.count > 2 else {
            for point in points.dropFirst() { path.addLine(to: point) }
            return path
        }

        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let control = CGPoint(
                x: (previous.x + current.x) / 2,
                y: previous.y
            )
            path.addQuadCurve(to: current, control: control)
        }
        return path
    }
}
