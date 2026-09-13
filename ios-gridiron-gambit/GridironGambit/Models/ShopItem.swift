import Foundation

/// A Game Ball currency pack sold in the shop (UI only in this phase).
nonisolated struct GameBallPack: Identifiable, Sendable, Hashable {
    let id: String
    let amount: Int
    let price: String
    let bonusLabel: String?
    /// Number of footballs drawn in the pack artwork, 1 through 4.
    let ballCount: Int
}

/// A non-currency shop offer such as a bundle or unlock.
nonisolated struct ShopOffer: Identifiable, Sendable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let price: String
    let perks: [String]
    let symbol: String
    let highlighted: Bool
}
