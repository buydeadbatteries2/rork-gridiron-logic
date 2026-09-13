import Foundation

/// Mutable solving state for the level currently on the board.
nonisolated struct PuzzleSession: Sendable, Hashable {
    /// X marks the player placed. Tap an empty square to add one, tap the X to
    /// remove it — marks are free and always removable.
    var marks: Set<String> = []
    /// Defenders currently on the board: cell id -> kind id.
    var revealed: [String: String] = [:]
    /// True while a player X mark sits on a hidden defender ("CHECK YOUR BLOCKS").
    var hasContradiction: Bool = false
    /// Times the player's deductions contradicted the rules. The only star cost.
    var mistakeCount: Int = 0
    /// Hints bought with Game Balls this level.
    var paidHints: Int = 0
    /// The one free hint per level.
    var freeHintUsed: Bool = false
    /// Cell the last hint highlighted; drives the gold pulse.
    var hintFlashCellId: String? = nil
    /// Transient banner text ("DEFENDER REVEALED!", "CHECK YOUR BLOCKS").
    var toastText: String? = nil
    var toastIsMistake: Bool = false
    /// Increments on each new toast so the UI can auto-dismiss it.
    var toastToken: Int = 0
    var isComplete: Bool = false
    var earnedStars: LevelStars = .none
}
