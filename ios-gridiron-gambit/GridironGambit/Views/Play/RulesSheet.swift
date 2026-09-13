import SwiftUI

/// Compact rules reference: the three universal puzzle rules plus the
/// tap-interaction cheat sheet.
struct RulesSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Palette.stroke)
                .frame(width: 40, height: 5)
                .padding(.top, 10)

            Text("HOW TO PLAY")
                .broadcastHeadline(22, tracking: 2)
                .foregroundStyle(Palette.chalk)
                .padding(.top, 14)

            VStack(spacing: 12) {
                ruleRow(number: "1", title: "ONE DEFENDER PER ZONE", message: "Each colored Coverage Zone hides exactly one defender.")
                ruleRow(number: "2", title: "ONE PER ROW + COLUMN", message: "Every row and every column contains exactly one hidden defender.")
                ruleRow(number: "3", title: "DEFENDERS CANNOT TOUCH", message: "Not horizontally, vertically, or diagonally.")
            }
            .padding(.top, 20)

            VStack(alignment: .leading, spacing: 8) {
                Label("Tap an empty square to mark an X.", systemImage: "hand.tap")
                Label("Tap the X again to remove it — marks are always free.", systemImage: "arrow.uturn.backward")
                Label("When your blocks leave one legal spot, the defender is revealed.", systemImage: "shield.fill")
                Label("BLOWN ASSIGNMENT: an X that makes the defense impossible is undone and costs one of your three downs.", systemImage: "exclamationmark.triangle")
                Label("Finish with downs to spare for more stars.", systemImage: "star.fill")
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Palette.muted)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Palette.surfaceRaised.opacity(0.55))
            }
            .padding(.top, 18)

            Button {
                dismiss()
            } label: {
                Text("GOT IT")
                    .broadcastHeadline(16, tracking: 1.5)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Palette.accentBright, Palette.accent],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
            }
            .buttonStyle(NodePressStyle())
            .padding(.top, 20)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .presentationDetents([.height(560)])
    }

    private func ruleRow(number: String, title: String, message: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number)
                .scoreboardNumber(17)
                .foregroundStyle(Palette.canvasDeep)
                .frame(width: 34, height: 34)
                .background {
                    Circle().fill(Palette.gold)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .broadcastHeadline(14, tracking: 1)
                    .foregroundStyle(Palette.chalk)
                Text(message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Palette.surface.opacity(0.9))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Palette.stroke, lineWidth: 1)
                }
        }
    }
}
