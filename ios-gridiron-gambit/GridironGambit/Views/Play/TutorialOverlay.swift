import SwiftUI

/// First-time, five-screen tutorial that teaches the three universal rules
/// in about ten seconds. Skippable; never shown again once finished.
struct TutorialOverlay: View {
    var onFinish: () -> Void

    @State private var page: Int = 0

    private struct TutorialStep {
        let symbol: String
        let tint: Color
        let title: String
        let message: String
    }

    private let steps: [TutorialStep] = [
        TutorialStep(
            symbol: "hand.tap.fill",
            tint: Palette.blue,
            title: "BLOCK THE FIELD",
            message: "Tap squares where a defender cannot be."
        ),
        TutorialStep(
            symbol: "rectangle.split.3x3",
            tint: Palette.blue,
            title: "ONE PER ROW",
            message: "Every row hides exactly one defender."
        ),
        TutorialStep(
            symbol: "rectangle.split.3x3.fill",
            tint: Palette.blue,
            title: "ONE PER COLUMN",
            message: "Every column hides exactly one defender."
        ),
        TutorialStep(
            symbol: "xmark.circle.fill",
            tint: Palette.accentBright,
            title: "DON'T TOUCH",
            message: "Defenders cannot touch — even diagonally."
        ),
        TutorialStep(
            symbol: "shield.fill",
            tint: Palette.gold,
            title: "REVEAL THE DEFENSE",
            message: "Block the wrong squares and the defenders will reveal themselves."
        ),
    ]

    private var step: TutorialStep { steps[page] }

    var body: some View {
        ZStack {
            Color.black.opacity(0.84)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                Image(systemName: step.symbol)
                    .font(.system(size: 44, weight: .black))
                    .foregroundStyle(step.tint)
                    .frame(width: 96, height: 96)
                    .background {
                        Circle()
                            .fill(Palette.surface.opacity(0.95))
                            .overlay {
                                Circle().stroke(step.tint.opacity(0.5), lineWidth: 1.5)
                            }
                            .shadow(color: step.tint.opacity(0.55), radius: 18)
                    }
                    .id(page)
                    .transition(.scale(scale: 0.7).combined(with: .opacity))

                Text(step.title)
                    .broadcastHeadline(27, tracking: 2)
                    .foregroundStyle(Palette.chalk)
                    .id("title-\(page)")
                    .transition(.move(edge: .trailing).combined(with: .opacity))

                Text(step.message)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .id("message-\(page)")
                    .transition(.move(edge: .trailing).combined(with: .opacity))

                Spacer()

                HStack(spacing: 8) {
                    ForEach(steps.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == page ? Palette.gold : Palette.stroke)
                            .frame(width: index == page ? 22 : 8, height: 8)
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: page)
                    }
                }

                HStack {
                    Button("Skip Tutorial", action: onFinish)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Palette.muted)

                    Spacer()

                    Button {
                        if page == steps.count - 1 {
                            onFinish()
                        } else {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                page += 1
                            }
                        }
                    } label: {
                        Text(page == steps.count - 1 ? "START LEVEL 1" : "NEXT")
                            .broadcastHeadline(15, tracking: 1.5)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 26)
                            .frame(height: 48)
                            .background {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Palette.accentBright, Palette.accent],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .shadow(color: Palette.accent.opacity(0.55), radius: 10, y: 3)
                            }
                    }
                    .buttonStyle(NodePressStyle())
                }
            }
            .padding(24)
        }
    }
}
