import SwiftUI

/// Pill-shaped scoreboard chip used across the top status bar.
nonisolated struct StatusPill<Leading: View>: View {
    let leading: Leading
    let value: String
    var valueColor: Color = Palette.chalk

    init(value: String, valueColor: Color = Palette.chalk, @ViewBuilder leading: () -> Leading) {
        self.value = value
        self.valueColor = valueColor
        self.leading = leading()
    }

    var body: some View {
        HStack(spacing: 7) {
            leading
            Text(value)
                .scoreboardNumber(16)
                .foregroundStyle(valueColor)
        }
        .padding(.leading, 6)
        .padding(.trailing, 14)
        .padding(.vertical, 6)
        .background {
            Capsule(style: .continuous)
                .fill(Palette.surface.opacity(0.92))
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(Palette.stroke.opacity(0.9), lineWidth: 1)
                }
        }
    }
}

/// Game Ball counter with football icon.
nonisolated struct GameBallDisplay: View {
    let amount: Int
    var size: CGFloat = 26

    private var formatted: String {
        amount.formatted(.number.grouping(.automatic))
    }

    var body: some View {
        StatusPill(value: formatted) {
            FootballIcon(size: size)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(formatted) game balls")
    }
}
