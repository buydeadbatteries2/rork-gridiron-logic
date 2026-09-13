import SwiftUI

/// A football-shaped node on the winding road.
struct LevelNode: View {
    let level: Level
    var onTap: (Level) -> Void

    @State private var pulse: Bool = false

    private var isCurrent: Bool { level.status == .current }

    private var bodyGradient: LinearGradient {
        switch level.status {
        case .current:
            LinearGradient(
                colors: [Color(hex: 0xE8394C), Color(hex: 0x9E1322)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .completed:
            LinearGradient(
                colors: [Color(hex: 0x2FA05C), Color(hex: 0x14653A)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .locked:
            LinearGradient(
                colors: [Color(hex: 0x2A3B54), Color(hex: 0x16202F)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    var body: some View {
        Button {
            onTap(level)
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    if isCurrent {
                        FootballShape()
                            .stroke(Palette.accentBright.opacity(0.85), lineWidth: 3)
                            .frame(width: 116, height: 76)
                            .blur(radius: 3)
                            .scaleEffect(pulse ? 1.16 : 1.0)
                            .opacity(pulse ? 0 : 0.9)
                    }

                    FootballShape()
                        .fill(bodyGradient)
                        .overlay {
                            FootballShape()
                                .stroke(
                                    isCurrent ? Palette.accentBright : Color.white.opacity(0.35),
                                    lineWidth: isCurrent ? 2.5 : 1.5
                                )
                        }
                        .overlay {
                            FootballLaces(tint: .white.opacity(level.isUnlocked ? 0.65 : 0.3))
                                .frame(width: 34, height: 30)
                                .offset(y: -2)
                                .opacity(level.isUnlocked ? 0.35 : 0.2)
                        }
                        .frame(width: 104, height: 66)
                        .shadow(
                            color: isCurrent ? Palette.accent.opacity(0.7) : .black.opacity(0.5),
                            radius: isCurrent ? 20 : 8,
                            y: 4
                        )

                    VStack(spacing: 2) {
                        Text("\(level.levelNumber)")
                            .scoreboardNumber(24)
                            .foregroundStyle(level.isUnlocked ? Palette.chalk : Palette.muted)

                        if !level.isUnlocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Palette.muted)
                        }
                    }
                }

                if level.isCompleted {
                    StarRow(stars: level.starsEarned, size: 14)
                } else if isCurrent {
                    StarRow(stars: .none, size: 14)
                }
            }
        }
        .buttonStyle(NodePressStyle())
        .disabled(!level.isUnlocked)
        .onAppear {
            guard isCurrent else { return }
            withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) {
                pulse = true
            }
        }
        .accessibilityLabel("Level \(level.levelNumber), \(level.title)")
        .accessibilityHint(level.isUnlocked ? "Opens the puzzle" : "Locked")
    }
}

/// Star rating row shown beneath level nodes.
nonisolated struct StarRow: View {
    let stars: LevelStars
    var size: CGFloat = 14

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...3, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: size, weight: .bold))
                    .foregroundStyle(index <= stars.rawValue ? Palette.gold : Color(hex: 0x46586F))
                    .shadow(color: index <= stars.rawValue ? Palette.gold.opacity(0.6) : .clear, radius: 4)
            }
        }
    }
}

/// Tactile press feedback for road nodes.
nonisolated struct NodePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
