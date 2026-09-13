import SwiftUI

/// Compact drive status: how many defenders have been found (DEFENSE 1/5…)
/// plus the three-down mistake allowance. Purely informational — the player
/// never manages defender types or downs here.
struct DefenseStatusBar: View {
    /// Kinds of the revealed defenders, in discovery order.
    let revealedKinds: [String]
    let total: Int
    let downs: Int

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("DEFENSE \(revealedKinds.count)/\(total)")
                    .broadcastLabel(9)
                    .foregroundStyle(Palette.muted)
                HStack(spacing: 5) {
                    ForEach(0..<total, id: \.self) { slot in
                        if slot < revealedKinds.count {
                            RevealMarker(kindId: revealedKinds[slot], size: 26)
                                .transition(.scale(scale: 0.4).combined(with: .opacity))
                        } else {
                            Circle()
                                .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                                .frame(width: 26, height: 26)
                                .overlay {
                                    Circle()
                                        .fill(Color.black.opacity(0.25))
                                        .frame(width: 22, height: 22)
                                }
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 5) {
                Text("DOWNS")
                    .broadcastLabel(9)
                    .foregroundStyle(Palette.muted)
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        FootballIcon(size: 18)
                            .opacity(index < downs ? 1 : 0.18)
                            .saturation(index < downs ? 1 : 0)
                    }
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: revealedKinds)
    }
}
