import Foundation

/// Lock/play state of a single puzzle level.
nonisolated enum LevelStatus: String, Sendable {
    case locked
    case current
    case completed
}

/// Star rating a level can award, 0 through 3.
nonisolated enum LevelStars: Int, CaseIterable, Sendable {
    case none = 0
    case one = 1
    case two = 2
    case three = 3
}

/// Relative challenge of a puzzle, shown on the level preview.
nonisolated enum LevelDifficulty: String, Sendable {
    case walkthrough = "Walkthrough"
    case standard = "Standard"
    case pressure = "Pressure"
    case championship = "Championship"
}

/// Prize granted for clearing a level.
nonisolated struct LevelReward: Sendable, Hashable {
    let gameBalls: Int
    let xp: Int
}

/// A single defensive puzzle on the road.
nonisolated struct Level: Identifiable, Sendable, Hashable {
    let levelNumber: Int
    let stadiumId: Int
    let title: String
    let difficulty: LevelDifficulty
    var starsEarned: LevelStars
    var isUnlocked: Bool
    var isCompleted: Bool
    let isGameDay: Bool
    let reward: LevelReward

    var id: Int { levelNumber }

    var status: LevelStatus {
        if isCompleted { return .completed }
        return isUnlocked ? .current : .locked
    }
}

/// A bonus stop placed between level clusters on the road.
nonisolated struct RewardStop: Identifiable, Sendable, Hashable {
    let id: Int
    let afterLevel: Int
    let gameBalls: Int
    var isClaimed: Bool
}

/// One visual stop rendered on the winding road.
nonisolated enum RoadStop: Identifiable, Sendable, Hashable {
    case level(Level)
    case gameDay(Level)
    case reward(RewardStop)

    var id: String {
        switch self {
        case .level(let level): "level-\(level.levelNumber)"
        case .gameDay(let level): "gameday-\(level.levelNumber)"
        case .reward(let stop): "reward-\(stop.id)"
        }
    }
}
