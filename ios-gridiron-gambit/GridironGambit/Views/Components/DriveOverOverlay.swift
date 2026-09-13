import SwiftUI

/// Shown when the third down is lost: the drive ends, try again restarts the
/// puzzle with a clean board and three fresh downs. No continues for now.
struct DriveOverOverlay: View {
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.78)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                FootballIcon(size: 44)
                    .grayscale(0.6)

                Text("DRIVE OVER")
                    .broadcastHeadline(30, tracking: 3)
                    .foregroundStyle(Palette.accentBright)

                Text("THREE DOWNS USED. THE DRIVE ENDS HERE.")
                    .broadcastLabel(11)
                    .foregroundStyle(Palette.muted)
                    .multilineTextAlignment(.center)

                Button {
                    onRetry()
                } label: {
                    Text("TRY AGAIN")
                        .broadcastHeadline(17, tracking: 2)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Palette.accentBright, Palette.accent],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: Palette.accent.opacity(0.5), radius: 12, y: 4)
                        }
                }
                .buttonStyle(NodePressStyle())
                .padding(.top, 8)
            }
            .padding(24)
            .frame(maxWidth: 300)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Palette.surface.opacity(0.98))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Palette.accent.opacity(0.45), lineWidth: 1.5)
                    }
                    .shadow(color: .black.opacity(0.6), radius: 24, y: 10)
            }
        }
        .transition(.opacity)
        .accessibilityElement(children: .contain)
    }
}
