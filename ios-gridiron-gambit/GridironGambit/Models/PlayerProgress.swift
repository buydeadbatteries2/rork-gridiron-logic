import Foundation

/// Coaching ranks unlocked as the player accumulates XP.
nonisolated enum PlayerRank: String, CaseIterable, Sendable {
    case rookie = "Rookie"
    case assistant = "Assistant"
    case positionCoach = "Position Coach"
    case coordinator = "Coordinator"
    case headCoach = "Head Coach"
    case legend = "Legend"
}

/// Locally stored player state. No backend in this phase.
nonisolated struct PlayerProgress: Sendable, Hashable {
    var playerLevel: Int
    var xp: Int
    var gameBalls: Int
    var stars: Int
    var rank: PlayerRank
    /// The lowest level that has not been cleared yet.
    var currentLevelNumber: Int

    /// XP needed to reach the next player level.
    var xpForNextLevel: Int { 100 + (playerLevel - 1) * 50 }

    var xpProgress: Double {
        guard xpForNextLevel > 0 else { return 0 }
        return min(1, Double(xp) / Double(xpForNextLevel))
    }

    static let starting = PlayerProgress(
        playerLevel: 1,
        xp: 0,
        gameBalls: 250,
        stars: 0,
        rank: .rookie,
        currentLevelNumber: 1
    )
}
