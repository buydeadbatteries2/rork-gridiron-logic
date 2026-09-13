import SwiftUI

/// Vector football helmet used in status chrome and locker tiles.
nonisolated struct HelmetGlyph: View {
    var shell: Color
    var facemask: Color
    var stripe: Color

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let width = size.width
            let height = size.height

            ZStack(alignment: .topLeading) {
                // Shell dome
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [shell.opacity(1), shell.opacity(0.72)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: width * 0.82, height: height * 0.82)
                    .offset(x: width * 0.04, y: 0)

                // Ear hole
                Circle()
                    .fill(Color.black.opacity(0.45))
                    .frame(width: width * 0.13, height: width * 0.13)
                    .offset(x: width * 0.30, y: height * 0.42)

                // Center stripe
                Capsule()
                    .fill(stripe)
                    .frame(width: width * 0.10, height: height * 0.44)
                    .offset(x: width * 0.36, y: height * 0.02)

                // Facemask bars
                Path { path in
                    let startX = width * 0.52
                    let endX = width * 0.94
                    for row in 0..<2 {
                        let y = height * (0.52 + Double(row) * 0.16)
                        path.move(to: CGPoint(x: startX, y: y))
                        path.addQuadCurve(
                            to: CGPoint(x: endX, y: y - height * 0.08),
                            control: CGPoint(x: (startX + endX) / 2, y: y + height * 0.06)
                        )
                    }
                }
                .stroke(facemask, style: StrokeStyle(lineWidth: max(1.2, width * 0.05), lineCap: .round))

                // Chin bar
                Path { path in
                    path.move(to: CGPoint(x: width * 0.50, y: height * 0.50))
                    path.addQuadCurve(
                        to: CGPoint(x: width * 0.58, y: height * 0.84),
                        control: CGPoint(x: width * 0.62, y: height * 0.70)
                    )
                }
                .stroke(facemask.opacity(0.85), style: StrokeStyle(lineWidth: max(1.2, width * 0.05), lineCap: .round))
            }
            .frame(width: width, height: height)
        }
        .aspectRatio(1.18, contentMode: .fit)
    }
}
