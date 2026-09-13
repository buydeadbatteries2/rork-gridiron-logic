import SwiftUI

/// The three defender types hidden in the defensive grid.
/// Broadcast color coding: corners blue, linebackers red, safeties gold.
nonisolated enum DefensePieceKind: String, CaseIterable, Sendable, Hashable {
    case cb
    case lb
    case s

    var abbreviation: String {
        switch self {
        case .cb: "CB"
        case .lb: "LB"
        case .s: "S"
        }
    }

    var name: String {
        switch self {
        case .cb: "Cornerback"
        case .lb: "Linebacker"
        case .s: "Safety"
        }
    }

    var color: Color {
        switch self {
        case .cb: Palette.blue
        case .lb: Palette.accent
        case .s: Palette.gold
        }
    }

    /// Text color that stays legible on the kind's marker.
    var labelColor: Color {
        self == .s ? Palette.canvasDeep : .white
    }

    static func kind(forID id: String) -> DefensePieceKind? {
        DefensePieceKind(rawValue: id)
    }
}
