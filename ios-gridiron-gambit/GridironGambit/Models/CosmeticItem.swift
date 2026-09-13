import SwiftUI

/// Locker customization categories.
nonisolated enum LockerCategory: String, CaseIterable, Identifiable, Sendable {
    case helmet = "Helmet"
    case uniform = "Uniform"
    case field = "Field"
    case stadium = "Stadium"
    case markers = "Markers"
    case celebration = "Celebration"

    var id: String { rawValue }
}

/// Visual treatment used to render a cosmetic preview tile.
nonisolated enum CosmeticPreview: Sendable, Hashable {
    case helmet(shell: Color, facemask: Color, stripe: Color)
    case uniform(jersey: Color, trim: Color)
    case turf(primary: Color, secondary: Color)
    case stadiumLights(tint: Color)
    case marker(symbol: String, tint: Color)
    case celebration(symbol: String, tint: Color)
}

/// A single unlockable cosmetic in the locker.
nonisolated struct CosmeticItem: Identifiable, Sendable, Hashable {
    let id: String
    let name: String
    let category: LockerCategory
    let preview: CosmeticPreview
    let price: Int
    var isOwned: Bool
    var isEquipped: Bool
}
