import SwiftUI

/// The 5x5 defensive logic grid, styled as a tactical coverage map layered
/// over turf. Five translucent Coverage Zones (one defender each) sit under
/// the rules: one per zone, one per row, one per column, no touching.
/// The single interaction: tap an empty square to place an X, tap the X to
/// remove it. The game never places X marks — only the player does.
struct DefensiveGrid: View {
    let puzzle: PuzzleDefinition
    let marks: Set<String>
    let revealed: [String: String]
    var hintFlashCellId: String?
    var guideCellId: String?
    var coachCellId: String?
    var blownCellId: String?
    var blownToken: Int = 0
    var onTap: (String) -> Void

    /// Restrained tactical tints for the five Coverage Zones (A–E), kept
    /// translucent so the turf stays dominant.
    static let zoneTints: [Color] = [
        Color(hex: 0x3E7BFA), // blue
        Color(hex: 0x2FB8A6), // teal
        Color(hex: 0x9B6BF2), // purple
        Color(hex: 0xE8A23D), // amber
        Color(hex: 0xE0263A), // crimson
    ]

    private let laneLabels = ["L OUT", "L IN", "MID", "R IN", "R OUT"]
    private let depthLabels = ["DEEP", "INTER", "UNDER", "SHORT", "LINE"]
    private let gap: CGFloat = 5
    private let leadingInset: CGFloat = 40

    var body: some View {
        VStack(spacing: 6) {
            columnHeaders
            grid
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x2A8B52), Color(hex: 0x1F6E40)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    // Faint yard lines keep the board reading as a football field.
                    VStack(spacing: 0) {
                        ForEach(0..<4, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.white.opacity(0.07))
                                .frame(height: 1)
                            Spacer(minLength: 0)
                        }
                    }
                    .padding(.vertical, 8)
                }
        }
    }

    // MARK: - Layout

    private var columnHeaders: some View {
        HStack(spacing: gap) {
            Color.clear.frame(width: leadingInset)
            ForEach(laneLabels, id: \.self) { label in
                Text(label)
                    .broadcastLabel(7)
                    .foregroundStyle(Palette.chalk.opacity(0.7))
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 12)
    }

    private var grid: some View {
        VStack(spacing: gap) {
            ForEach(0..<5, id: \.self) { row in
                HStack(spacing: gap) {
                    Text(depthLabels[row])
                        .broadcastLabel(7)
                        .foregroundStyle(Palette.chalk.opacity(0.7))
                        .frame(width: leadingInset, alignment: .trailing)

                    ForEach(0..<5, id: \.self) { column in
                        cellView(row: row, column: column)
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
    }

    // MARK: - Coverage Zone visuals

    private func zoneAt(row: Int, column: Int) -> Int? {
        guard row >= 0, row < 5, column >= 0, column < 5 else { return nil }
        return puzzle.zoneOf[PuzzleEngine.cellId(row: row, column: column)]
    }

    /// Subtle boundary lines on the edges where a cell meets a DIFFERENT
    /// zone, so each coverage area reads as one contiguous region.
    @ViewBuilder
    private func zoneBoundaries(row: Int, column: Int, zone: Int) -> some View {
        let tint = Self.zoneTints[zone]
        let top = zoneAt(row: row - 1, column: column)
        let bottom = zoneAt(row: row + 1, column: column)
        let leading = zoneAt(row: row, column: column - 1)
        let trailing = zoneAt(row: row, column: column + 1)

        Color.clear
            .overlay(alignment: .top) {
                if let top, top != zone {
                    Rectangle().fill(tint.opacity(0.6)).frame(height: 1.5)
                }
            }
            .overlay(alignment: .bottom) {
                if let bottom, bottom != zone {
                    Rectangle().fill(tint.opacity(0.6)).frame(height: 1.5)
                }
            }
            .overlay(alignment: .leading) {
                if let leading, leading != zone {
                    Rectangle().fill(tint.opacity(0.6)).frame(width: 1.5)
                }
            }
            .overlay(alignment: .trailing) {
                if let trailing, trailing != zone {
                    Rectangle().fill(tint.opacity(0.6)).frame(width: 1.5)
                }
            }
            .padding(2)
            .allowsHitTesting(false)
    }

    // MARK: - Cells

    @ViewBuilder
    private func cellView(row: Int, column: Int) -> some View {
        let cellId = PuzzleEngine.cellId(row: row, column: column)
        let zone = puzzle.zoneOf[cellId]
        let isBlown = cellId == blownCellId

        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(marks.contains(cellId) ? 0.34 : 0.26))

            if let zone {
                // Translucent coverage tint — structure, never an X mark.
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Self.zoneTints[zone].opacity(0.20))
                zoneBoundaries(row: row, column: column, zone: zone)
            }

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(
                    revealed[cellId] != nil ? Palette.gold.opacity(0.7) : Color.white.opacity(0.22),
                    lineWidth: 1
                )

            if let kindId = revealed[cellId] {
                RevealMarker(kindId: kindId)
                    .transition(.scale(scale: 0.3).combined(with: .opacity))
            } else if marks.contains(cellId) {
                // Player mark: bright, always removable.
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(Palette.accentBright)
                    .shadow(color: Palette.accent.opacity(0.7), radius: 4)
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
            } else {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 7, height: 7)
            }

            if cellId == hintFlashCellId {
                HintPulse()
            }
            if cellId == guideCellId {
                GuidePulse()
            }
            if cellId == coachCellId, guideCellId == nil {
                CoachPulse()
            }
        }
        .blownShake(isActive: isBlown, token: blownToken)
        .contentShape(.rect)
        .onTapGesture { onTap(cellId) }
        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: marks)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: revealed)
        .animation(.easeInOut(duration: 0.3), value: blownCellId)
    }
}

/// Pulsing highlight on the square the guided tutorial wants tapped.
private struct GuidePulse: View {
    @State private var pulse = false

    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Palette.gold.opacity(pulse ? 0.22 : 0.05))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Palette.gold, lineWidth: 2.5)
                    .scaleEffect(pulse ? 1.08 : 1.0)
                    .opacity(pulse ? 0.35 : 1.0)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
            .allowsHitTesting(false)
    }
}

/// Soft one-time starting nudge ("COACH'S READ") on a useful square.
private struct CoachPulse: View {
    @State private var pulse = false

    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .stroke(Color.white.opacity(pulse ? 0.85 : 0.3), lineWidth: 2)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(pulse ? 0.10 : 0.02))
            }
            .scaleEffect(pulse ? 1.05 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
            .allowsHitTesting(false)
    }
}

/// A revealed defender: colored circular marker with the position label.
nonisolated struct RevealMarker: View {
    let kindId: String
    var size: CGFloat = 34

    var body: some View {
        let kind = DefensePieceKind.kind(forID: kindId) ?? .cb
        Text(kind.abbreviation)
            .broadcastHeadline(13, tracking: 0.5)
            .foregroundStyle(kind.labelColor)
            .frame(width: size, height: size)
            .background {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [kind.color, kind.color.opacity(0.62)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay {
                        Circle().stroke(Color.white.opacity(0.9), lineWidth: 2)
                    }
                    .shadow(color: kind.color.opacity(0.8), radius: 7)
            }
            .accessibilityLabel("\(kind.name) revealed")
    }
}
