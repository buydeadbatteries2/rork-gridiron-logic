import SwiftUI

/// The winding vertical road of level stops drawn over turf.
/// Stops arrive ordered top-to-bottom (highest level first), so the player
/// travels upward toward the stadium marquee.
struct StadiumRoadmap: View {
    let stadium: Stadium
    let stops: [RoadStop]
    var onSelect: (Level) -> Void

    /// Horizontal offsets, in points, cycled to create the serpentine path.
    private let sway: [CGFloat] = [0, 62, 8, -58, -6, 58, -4, -62]
    private let rowHeight: CGFloat = 108

    private func offset(for index: Int) -> CGFloat {
        sway[index % sway.count]
    }

    var body: some View {
        ZStack {
            RoadPath(
                offsets: stops.indices.map { offset(for: $0) },
                rowHeight: rowHeight,
                highlightIndex: currentIndex
            )

            VStack(spacing: 0) {
                ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                    stopView(stop)
                        .frame(height: rowHeight)
                        .offset(x: offset(for: index))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// Index of the stop holding the player's current level, used to tint the path.
    private var currentIndex: Int? {
        stops.firstIndex { stop in
            switch stop {
            case .level(let level), .gameDay(let level):
                return level.status == .current
            case .reward:
                return false
            }
        }
    }

    @ViewBuilder
    private func stopView(_ stop: RoadStop) -> some View {
        switch stop {
        case .level(let level):
            LevelNode(level: level, onTap: onSelect)
        case .gameDay(let level):
            GameDayNode(level: level, onTap: onSelect)
        case .reward(let reward):
            RewardNode(stop: reward)
        }
    }
}

/// Chalk-style connecting path between road stops.
nonisolated struct RoadPath: View {
    let offsets: [CGFloat]
    let rowHeight: CGFloat
    let highlightIndex: Int?

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let centerX = width / 2

            let points: [CGPoint] = offsets.enumerated().map { index, offset in
                CGPoint(x: centerX + offset, y: rowHeight * (CGFloat(index) + 0.5))
            }

            ZStack {
                // Base road
                CurvedPath(points: points)
                    .stroke(
                        Color.white.opacity(0.30),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round, lineJoin: .round)
                    )

                CurvedPath(points: points)
                    .stroke(
                        Color.white.opacity(0.55),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [10, 12])
                    )

                // Travelled segment below the current stop glows red
                if let highlightIndex, highlightIndex < points.count - 1 {
                    CurvedPath(points: Array(points[highlightIndex...]))
                        .stroke(
                            LinearGradient(
                                colors: [Palette.accentBright, Palette.accent.opacity(0.4)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round)
                        )
                        .shadow(color: Palette.accent.opacity(0.7), radius: 10)
                }
            }
        }
        .frame(height: rowHeight * CGFloat(offsets.count))
        .allowsHitTesting(false)
    }
}

/// Smooth Catmull-Rom-ish curve through the supplied points.
nonisolated struct CurvedPath: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)

        guard points.count > 1 else { return path }

        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let midY = (previous.y + current.y) / 2
            path.addCurve(
                to: current,
                control1: CGPoint(x: previous.x, y: midY),
                control2: CGPoint(x: current.x, y: midY)
            )
        }
        return path
    }
}
