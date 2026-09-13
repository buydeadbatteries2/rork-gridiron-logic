import SwiftUI

/// The dramatic chapter-finale node shown at the top of each stadium road.
struct GameDayNode: View {
    let level: Level
    var onTap: (Level) -> Void

    @State private var shimmer: Bool = false

    var body: some View {
        Button {
            onTap(level)
        } label: {
            ZStack {
                // Elevated platform under the marquee node
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [Palette.surfaceRaised, Palette.canvasDeep],
                            center: .center,
                            startRadius: 6,
                            endRadius: 120
                        )
                    )
                    .frame(width: 210, height: 88)
                    .overlay {
                        Ellipse()
                            .stroke(Color.white.opacity(0.28), lineWidth: 2)
                    }
                    .shadow(color: .black.opacity(0.6), radius: 16, y: 8)

                Ellipse()
                    .stroke(
                        level.isUnlocked ? Palette.gold.opacity(0.8) : Palette.stroke,
                        lineWidth: 2
                    )
                    .frame(width: 176, height: 64)
                    .opacity(shimmer ? 0.9 : 0.4)

                VStack(spacing: 5) {
                    Text("GAME DAY")
                        .broadcastHeadline(26, tracking: 2)
                        .foregroundStyle(level.isUnlocked ? Palette.chalk : Palette.muted)

                    if level.isUnlocked {
                        StarRow(stars: level.starsEarned, size: 13)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Palette.muted)
                    }
                }
                .offset(y: -2)
            }
        }
        .buttonStyle(NodePressStyle())
        .disabled(!level.isUnlocked)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                shimmer = true
            }
        }
        .accessibilityLabel("Game Day, level \(level.levelNumber)")
        .accessibilityHint(level.isUnlocked ? "Opens the finale puzzle" : "Locked")
    }
}

/// Bonus chest stop placed between level clusters.
struct RewardNode: View {
    let stop: RewardStop

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0x2C3E5A), Color(hex: 0x16202F)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 74, height: 58)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Palette.gold.opacity(0.6), lineWidth: 1.5)
                    }
                    .shadow(color: Palette.gold.opacity(0.25), radius: 12)

                HStack(spacing: 4) {
                    FootballIcon(size: 20)
                    Text("+\(stop.gameBalls)")
                        .scoreboardNumber(13)
                        .foregroundStyle(Palette.gold)
                }
            }

            Text("REWARD")
                .broadcastLabel(9)
                .foregroundStyle(Palette.muted)
        }
        .accessibilityLabel("Reward stop, \(stop.gameBalls) game balls")
    }
}
