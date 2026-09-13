import SwiftUI

/// Core color tokens for the broadcast-football visual system.
nonisolated enum Palette {
    static let canvas = Color(hex: 0x0B1220)
    static let canvasDeep = Color(hex: 0x05080F)
    static let surface = Color(hex: 0x132033)
    static let surfaceRaised = Color(hex: 0x1B2C44)
    static let stroke = Color(hex: 0x2A3B54)

    static let field = Color(hex: 0x1E7A46)
    static let fieldDeep = Color(hex: 0x114A2B)
    static let fieldLight = Color(hex: 0x2FA05C)

    static let accent = Color(hex: 0xE0263A)
    static let accentBright = Color(hex: 0xFF4257)
    static let blue = Color(hex: 0x3E7BFA)
    static let gold = Color(hex: 0xFFC53D)

    static let chalk = Color(hex: 0xF2F6FB)
    static let muted = Color(hex: 0x8FA3BF)
    static let locked = Color(hex: 0x33445E)
}

nonisolated extension Color {
    /// Creates a color from a 24-bit RGB hex literal, e.g. `0x0B1220`.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
