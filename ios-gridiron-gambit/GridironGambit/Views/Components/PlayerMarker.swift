import SwiftUI

/// Circular chip representing an offensive player on the play diagram.
nonisolated struct PlayerMarker: View {
    let label: String
    var isEligible: Bool = true
    var diameter: CGFloat = 30

    var body: some View {
        Text(label)
            .font(.system(size: diameter * 0.36, weight: .black))
            .foregroundStyle(Palette.chalk)
            .frame(width: diameter, height: diameter)
            .background {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isEligible
                                ? [Color(hex: 0xE8394C), Color(hex: 0xA0182A)]
                                : [Color(hex: 0xC22636), Color(hex: 0x7E1122)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay {
                        Circle().stroke(Color.white.opacity(0.9), lineWidth: 2)
                    }
                    .shadow(color: .black.opacity(0.55), radius: 4, y: 2)
            }
            .accessibilityLabel("\(label) offensive player")
    }
}
