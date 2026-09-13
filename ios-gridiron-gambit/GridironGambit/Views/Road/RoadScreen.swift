import SwiftUI

/// ROAD tab: the primary progression surface.
struct RoadScreen: View {
    @Environment(GameState.self) private var game
    @State private var showsSettings: Bool = false

    private var stadium: Stadium { game.currentStadium }

    var body: some View {
        ZStack(alignment: .top) {
            StadiumSkyBackdrop()

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        StadiumMarquee(
                            stadium: stadium,
                            playsRemaining: game.playsToStadium(for: stadium)
                        )
                        .padding(.top, 8)

                        roadBody
                            .id("road-body")

                        nextStadiumTeaser
                            .padding(.top, 28)
                    }
                    .padding(.top, 76)
                    .padding(.bottom, 140)
                }
                .onAppear {
                    proxy.scrollTo("current-stop", anchor: .center)
                }
            }

            TopStatusBar(progress: game.progress) { showsSettings = true }
                .background {
                    LinearGradient(
                        colors: [Palette.canvasDeep.opacity(0.98), Palette.canvasDeep.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(edges: .top)
                }
        }
        .sheet(isPresented: $showsSettings) {
            SettingsSheet()
        }
    }

    /// The turf-backed winding road for the active stadium.
    private var roadBody: some View {
        let stops = game.roadStops(for: stadium)

        return StadiumRoadmap(stadium: stadium, stops: stops) { level in
            game.openLevel(level)
        }
        .padding(.top, 12)
        .background {
            TurfBackdrop(stripeCount: max(6, stops.count))
                .overlay {
                    LinearGradient(
                        colors: [
                            Palette.canvasDeep.opacity(0.85),
                            Palette.canvasDeep.opacity(0.15),
                            Palette.canvasDeep.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .overlay {
                    // Stadium light pools washing across the turf.
                    RadialGradient(
                        colors: [Color(hex: 0xDCEBFF).opacity(0.16), .clear],
                        center: UnitPoint(x: 0.1, y: 0.05),
                        startRadius: 10,
                        endRadius: 320
                    )
                }
        }
        .overlay(alignment: .top) {
            // Anchor used to auto-scroll to the player's current position.
            Color.clear
                .frame(height: 1)
                .id("current-stop")
                .offset(y: currentStopOffset(in: stops))
        }
    }

    /// Approximate vertical offset of the current level within the road.
    private func currentStopOffset(in stops: [RoadStop]) -> CGFloat {
        let index = stops.firstIndex { stop in
            switch stop {
            case .level(let level), .gameDay(let level): level.status == .current
            case .reward: false
            }
        }
        return CGFloat(index ?? 0) * 108
    }

    private var nextStadiumTeaser: some View {
        let nextStadium = game.stadiums.first { $0.id == stadium.id + 1 }

        return Group {
            if let nextStadium {
                VStack(spacing: 10) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Palette.muted)

                    Text("UP NEXT")
                        .broadcastLabel(10)
                        .foregroundStyle(Palette.muted)

                    Text(nextStadium.tagline)
                        .broadcastHeadline(24, tracking: 2)
                        .foregroundStyle(Palette.chalk.opacity(0.85))

                    Text(nextStadium.levelRangeText.uppercased())
                        .broadcastLabel(10)
                        .foregroundStyle(Palette.muted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 26)
                .background {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Palette.surface.opacity(0.6))
                        .overlay {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Palette.stroke, lineWidth: 1)
                        }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}
