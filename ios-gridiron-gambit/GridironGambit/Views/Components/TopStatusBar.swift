import SwiftUI

/// Persistent scoreboard chrome: player level, currency, stars, settings.
struct TopStatusBar: View {
    let progress: PlayerProgress
    var onSettings: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            StatusPill(value: "LVL \(progress.playerLevel)") {
                HelmetGlyph(
                    shell: Palette.surfaceRaised,
                    facemask: Palette.muted,
                    stripe: Palette.blue
                )
                .frame(width: 28, height: 24)
            }

            GameBallDisplay(amount: progress.gameBalls)

            StatusPill(value: "\(progress.stars)") {
                Image(systemName: "star.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Palette.gold)
                    .frame(width: 26, height: 24)
            }

            Spacer(minLength: 0)

            Button(action: onSettings) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Palette.chalk)
                    .frame(width: 42, height: 42)
                    .background {
                        Circle()
                            .fill(Palette.surface.opacity(0.92))
                            .overlay { Circle().stroke(Palette.stroke, lineWidth: 1) }
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
