import SwiftUI

/// A vesica-piscis football silhouette used for level nodes and currency icons.
nonisolated struct FootballShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let left = CGPoint(x: rect.minX, y: rect.midY)
        let right = CGPoint(x: rect.maxX, y: rect.midY)
        let lift = rect.height * 0.78

        path.move(to: left)
        path.addQuadCurve(to: right, control: CGPoint(x: rect.midX, y: rect.midY - lift))
        path.addQuadCurve(to: left, control: CGPoint(x: rect.midX, y: rect.midY + lift))
        path.closeSubpath()
        return path
    }
}

/// Laces + seam detail drawn on top of a football body.
nonisolated struct FootballLaces: View {
    var tint: Color = Palette.chalk
    var lineWidth: CGFloat = 1.4

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let laceWidth = size.width * 0.20
            let spacing = size.height * 0.13

            ZStack {
                Capsule()
                    .stroke(tint.opacity(0.55), lineWidth: lineWidth)
                    .frame(width: laceWidth, height: size.height * 0.46)

                VStack(spacing: spacing) {
                    ForEach(0..<3, id: \.self) { _ in
                        Rectangle()
                            .fill(tint.opacity(0.75))
                            .frame(width: laceWidth * 0.62, height: lineWidth)
                    }
                }
            }
            .frame(width: size.width, height: size.height)
        }
    }
}

/// Small football glyph used inline with currency amounts.
nonisolated struct FootballIcon: View {
    var size: CGFloat = 22

    var body: some View {
        FootballShape()
            .fill(
                LinearGradient(
                    colors: [Color(hex: 0xA8532A), Color(hex: 0x6E3218)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                FootballShape()
                    .stroke(Color(hex: 0xF4E4D4).opacity(0.7), lineWidth: size * 0.05)
            }
            .overlay {
                FootballLaces(tint: Color(hex: 0xFBF3EA), lineWidth: max(1, size * 0.055))
                    .frame(width: size * 0.5, height: size * 0.42)
            }
            .frame(width: size, height: size * 0.66)
    }
}
