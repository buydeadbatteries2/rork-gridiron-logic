import SwiftUI

/// Coaching banner for the guided Level 1 tutorial: one instruction at a time,
/// teaching through action on the real board. Shows a Skip control while the
/// guide is still pointing at squares.
struct GuideBanner: View {
    let message: String
    var showsSkip: Bool
    var onSkip: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Palette.gold)

            Text(message)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.chalk)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .id(message)
                .transition(.opacity.combined(with: .move(edge: .leading)))

            if showsSkip {
                Button(action: onSkip) {
                    Text("SKIP")
                        .broadcastLabel(10)
                        .foregroundStyle(Palette.muted)
                        .padding(.horizontal, 10)
                        .frame(height: 30)
                        .background {
                            Capsule().fill(Palette.surfaceRaised.opacity(0.7))
                        }
                }
                .buttonStyle(NodePressStyle())
                .accessibilityLabel("Skip tutorial")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Palette.surface.opacity(0.96))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Palette.gold.opacity(0.55), lineWidth: 1)
                }
        }
    }
}
