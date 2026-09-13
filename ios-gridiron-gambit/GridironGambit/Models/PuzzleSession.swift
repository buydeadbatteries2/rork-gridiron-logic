import Foundation

/// Mutable solving state for the level currently on the board.
nonisolated struct PuzzleSession: Sendable, Hashable {
    /// X marks the player placed. Freely removable — they never affect stars.
    var marks: Set<String> = []
    /// X marks derived automatically: starting clues plus every cell ruled out
    /// by a revealed defender's row, column, or neighborhood.
    var autoEliminated: Set<String> = []
    /// Cells proven empty by a failed reveal attempt — locked X's.
    var mistakes: Set<String> = []
    /// Defenders currently on the board: cell id -> kind id.
    var revealed: [String: String] = [:]
    /// Failed reveal attempts this level. The only thing that costs stars.
    var wrongReveals: Int = 0
    /// Hints bought with Game Balls this level.
    var paidHints: Int = 0
    /// The one free hint per level.
    var freeHintUsed: Bool = false
    /// Cell the last hint resolved; drives the gold pulse.
    var hintFlashCellId: String? = nil
    /// Cell that just failed a reveal attempt; drives the shake.
    var mistakeCellId: String? = nil
    /// Increments to retrigger mistake feedback (shake, haptic, toast).
    var mistakeToken: Int = 0
    /// Transient banner text ("DEFENDER REVEALED!", "NOT HERE").
    var toastText: String? = nil
    var toastIsMistake: Bool = false
    /// Increments on each new toast so the UI can auto-dismiss it.
    var toastToken: Int = 0
    var isComplete: Bool = false
    var earnedStars: LevelStars = .none
}
