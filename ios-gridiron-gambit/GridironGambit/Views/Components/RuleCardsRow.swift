import SwiftUI

/// Compact always-visible rule strip above the puzzle grid. Three cards,
/// row + column combined to fit mobile width. The full rules sheet stays
/// available for detail.
struct RuleCardsRow: View {
    var body: some View {
        HStack(spacing: 8) {
            ruleCard(icon: { zoneIcon }, label: "ONE PER\nZONE")
            ruleCard(icon: { rowColumnIcon }, label: "ONE PER\nROW + COLUMN")
            ruleCard(icon: { noTouchIcon }, label: "DON'T\nTOUCH")
        }
    }

    private func ruleCard(@ViewBuilder icon: () -> some View, label: String) -> some View {
        VStack(spacing: 6) {
            icon()
                .frame(height: 34)
            Text(label)
                .broadcastLabel(8)
                .foregroundStyle(Palette.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .padding(.horizontal, 4)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Palette.surface.opacity(0.9))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Palette.stroke, lineWidth: 1)
                }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label.replacingOccurrences(of: "\n", with: " "))
    }

    // MARK: - Mini icons

    /// Colored cells with one defender inside a zone.
    private var zoneIcon: some View {
        HStack(spacing: 3) {
            zoneCell(tint: DefensiveGrid.zoneTints[0])
            VStack(spacing: 3) {
                zoneCell(tint: DefensiveGrid.zoneTints[1])
                zoneCell(tint: DefensiveGrid.zoneTints[1], defender: true)
            }
            zoneCell(tint: DefensiveGrid.zoneTints[0])
        }
    }

    private func zoneCell(tint: Color, defender: Bool = false) -> some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(tint.opacity(0.3))
            .overlay {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .stroke(tint.opacity(0.8), lineWidth: 1)
                if defender {
                    Circle()
                        .fill(Palette.gold)
                        .frame(width: 8, height: 8)
                }
            }
            .frame(width: 13, height: 13)
    }

    /// Mini grid with one defender per row and per column.
    private var rowColumnIcon: some View {
        VStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { column in
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(Color.white.opacity(0.10))
                            .overlay {
                                if row == column {
                                    Circle()
                                        .fill(Palette.gold)
                                        .frame(width: 6, height: 6)
                                }
                            }
                            .frame(width: 11, height: 9)
                    }
                }
            }
        }
    }

    /// Defender with X'd squares all around it.
    private var noTouchIcon: some View {
        ZStack {
            Circle()
                .stroke(Palette.accent.opacity(0.7), style: StrokeStyle(lineWidth: 1.5, dash: [2.5, 2.5]))
                .frame(width: 30, height: 30)
            Circle()
                .fill(Palette.gold)
                .frame(width: 10, height: 10)
            Image(systemName: "xmark")
                .font(.system(size: 7, weight: .black))
                .foregroundStyle(Palette.accentBright)
                .offset(x: 0, y: -19)
            Image(systemName: "xmark")
                .font(.system(size: 7, weight: .black))
                .foregroundStyle(Palette.accentBright)
                .offset(x: -18, y: 9)
            Image(systemName: "xmark")
                .font(.system(size: 7, weight: .black))
                .foregroundStyle(Palette.accentBright)
                .offset(x: 18, y: 9)
        }
        .frame(height: 34)
    }
}
