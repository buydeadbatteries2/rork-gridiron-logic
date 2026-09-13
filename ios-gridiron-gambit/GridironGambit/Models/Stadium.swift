import Foundation

/// A chapter of 15 levels ending in a Game Day showdown.
nonisolated struct Stadium: Identifiable, Sendable, Hashable {
    let id: Int
    let name: String
    let tagline: String
    let firstLevel: Int
    let lastLevel: Int
    var isUnlocked: Bool
    /// Short motivational banners shown flanking the stadium marquee.
    let leftBanner: String
    let rightBanner: String

    var levelRangeText: String { "Levels \(firstLevel)-\(lastLevel)" }
    var totalLevels: Int { lastLevel - firstLevel + 1 }
}
