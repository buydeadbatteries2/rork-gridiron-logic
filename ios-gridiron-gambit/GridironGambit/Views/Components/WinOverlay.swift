import SwiftUI

/// Full-screen celebration after a correct defensive call: star reveal,
/// rewards, the equipped celebration cosmetic, and the next-play CTA.
struct WinOverlay: View {
    let stars: LevelStars
    let reward: LevelReward
    let levelTitle: String
    let celebration: CosmeticPreview?
    let canPlayNext: Bool
    var onNext: () -> Void
    var onReplay: () -> Void

    @State private var isRevealed = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.78)
                .ignoresSafeArea()

            // Stadium light beams behind the card.
            RadialGradient(
                colors: [Palette.gold.opacity(0.28), .clear],
                center: .top,
                startRadius: 20,
                endRadius: 480
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 18) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 34, weight: .black))
                    .foregroundStyle(Palette.accentBright)
                    .padding(16)
                    .background {
                        Circle()
                            .fill(Palette.surface.opacity(0.95))
                            .overlay { Circle().stroke(Palette.accent.opacity(0.5), lineWidth: 1.5) }
                            .shadow(color: Palette.accent.opacity(0.5), radius: 18)
                    }
                    .scaleEffect(isRevealed ? 1 : 0.4)
                    .opacity(isRevealed ? 1 : 0)

                Text("DEFENSE SET!")
                    .broadcastHeadline(34, tracking: 2)
                    .foregroundStyle(Palette.chalk)
                    .scaleEffect(isRevealed ? 1 : 0.7)
                    .opacity(isRevealed ? 1 : 0)

                Text("Every threat is covered.")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.muted)
                    .opacity(isRevealed ? 1 : 0)

                Text(levelTitle.uppercased())
                    .broadcastLabel(11)
                    .foregroundStyle(Palette.muted)

                HStack(spacing: 14) {
                    ForEach(1...3, id: \.self) { position in
                        Image(systemName: position <= stars.rawValue ? "star.fill" : "star")
                            .font(.system(size: 42, weight: .black))
                            .foregroundStyle(position <= stars.rawValue ? Palette.gold : Palette.locked)
                            .shadow(color: position <= stars.rawValue ? Palette.gold.opacity(0.6) : .clear, radius: 10)
                            .scaleEffect(isRevealed ? 1 : 0.2)
                            .opacity(isRevealed ? 1 : 0)
                            .animation(
                                .spring(response: 0.45, dampingFraction: 0.55)
                                    .delay(0.25 + Double(position) * 0.18),
                                value: isRevealed
                            )
                    }
                }

                if let celebration {
                    CelebrationBadge(preview: celebration)
                        .scaleEffect(isRevealed ? 1 : 0.5)
                        .opacity(isRevealed ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.85), value: isRevealed)
                }

                HStack(spacing: 18) {
                    RewardTag(
                        symbol: "figure.american.football",
                        value: "+\(reward.gameBalls)",
                        label: "GAME BALLS"
                    )
                    RewardTag(
                        symbol: "bolt.fill",
                        value: "+\(reward.xp)",
                        label: "XP"
                    )
                }
                .opacity(isRevealed ? 1 : 0)
                .offset(y: isRevealed ? 0 : 14)
                .animation(.easeOut(duration: 0.4).delay(0.95), value: isRevealed)

                VStack(spacing: 10) {
                    Button(action: onNext) {
                        Text(canPlayNext ? "NEXT PLAY" : "BACK TO THE ROAD")
                            .broadcastHeadline(19, tracking: 1.5)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [Palette.accentBright, Palette.accent],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .shadow(color: Palette.accent.opacity(0.55), radius: 12, y: 4)
                            }
                    }
                    .buttonStyle(NodePressStyle())

                    Button("REPLAY", action: onReplay)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Palette.muted)
                }
                .opacity(isRevealed ? 1 : 0)
                .animation(.easeOut(duration: 0.35).delay(1.1), value: isRevealed)
            }
            .padding(24)
            .padding(.vertical, 10)
            .frame(maxWidth: 340)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Palette.surface.opacity(0.98))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Palette.stroke, lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.6), radius: 30, y: 10)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isRevealed = true
            }
        }
    }
}

/// The equipped celebration cosmetic shown during the win.
nonisolated struct CelebrationBadge: View {
    let preview: CosmeticPreview

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Palette.gold.opacity(0.16))
                    .overlay { Circle().stroke(Palette.gold.opacity(0.6), lineWidth: 1.5) }
                    .frame(width: 58, height: 58)

                switch preview {
                case .celebration(let symbol, let tint):
                    Image(systemName: symbol)
                        .font(.system(size: 26, weight: .black))
                        .foregroundStyle(tint)
                default:
                    Image(systemName: "sparkles")
                        .font(.system(size: 26, weight: .black))
                        .foregroundStyle(Palette.gold)
                }
            }

            Text("CELEBRATION")
                .broadcastLabel(8)
                .foregroundStyle(Palette.muted)
        }
    }
}

/// Small reward readout used on the win card.
nonisolated struct RewardTag: View {
    let symbol: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Palette.accentBright)
            Text(value)
                .scoreboardNumber(17)
                .foregroundStyle(Palette.chalk)
            Text(label)
                .broadcastLabel(8)
                .foregroundStyle(Palette.muted)
        }
        .frame(minWidth: 110)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Palette.surfaceRaised.opacity(0.65))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Palette.stroke, lineWidth: 1)
                }
        }
    }
}
