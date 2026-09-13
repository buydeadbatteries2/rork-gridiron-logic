import SwiftUI

/// Top-down offensive play diagram: turf, line of scrimmage, personnel, and
/// route arrows. Purely thematic — the defensive puzzle lives in the grid below.
struct FootballField: View {
    let play: OffensivePlay

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            ZStack(alignment: .topLeading) {
                TurfBackdrop(
                    primary: Color(hex: 0x2A8B52),
                    secondary: Color(hex: 0x1F6E40),
                    showsNumbers: true,
                    stripeCount: 4
                )

                // Defensive-half wash: subtle blue tint downfield.
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Palette.blue.opacity(0.22), Palette.blue.opacity(0.04)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: size.height * play.lineOfScrimmage)

                // Line of scrimmage
                Rectangle()
                    .fill(Palette.blue)
                    .frame(width: size.width, height: 2.5)
                    .shadow(color: Palette.blue.opacity(0.8), radius: 4)
                    .offset(y: size.height * play.lineOfScrimmage - 26)

                ForEach(play.routes) { route in
                    RouteArrow(route: route, fieldSize: size)
                }

                ForEach(play.markers) { marker in
                    PlayerMarker(label: marker.label, isEligible: marker.isEligible)
                        .position(
                            x: marker.point.x * size.width,
                            y: marker.point.y * size.height
                        )
                }
            }
            .frame(width: size.width, height: size.height)
        }
        .clipShape(.rect(cornerRadius: 4))
    }
}

/// Gold pulsing ring marking the cell a hint just resolved.
struct HintPulse: View {
    @State private var isPulsing = false

    var body: some View {
        Circle()
            .stroke(Palette.gold, lineWidth: 3)
            .frame(width: 44, height: 44)
            .scaleEffect(isPulsing ? 1.25 : 0.85)
            .opacity(isPulsing ? 0.15 : 0.9)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
            .allowsHitTesting(false)
    }
}
