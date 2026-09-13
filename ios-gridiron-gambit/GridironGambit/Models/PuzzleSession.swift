import Foundation

/// Mutable solving state for the level currently on the board.
nonisolated struct PuzzleSession: Sendable, Hashable {
    /// X marks the player placed. Tap an empty square to add one, tap the X to
    /// remove it — marks are free and always removable.
    var marks: Set<String> = []
    /// Defenders currently on the board: cell id -> kind id.
    var revealed: [String: String] = [:]
    /// Mistake allowance. Three downs per drive; a blown assignment costs one.
    var downs: Int = 3
    /// Cell whose X is being undone as a blown assignment (drives the shake).
    var blownCellId: String? = nil
    /// Increments on each blown assignment so the UI can shake that cell.
    var blownToken: Int = 0
    /// True while a blown assignment is on screen and the bad X is being undone.
    var isAwaitingUndo: Bool = false
    /// True when the third down was lost ("DRIVE OVER").
    var isDriveOver: Bool = false
    /// One-time starting nudge ("COACH'S READ"): pulses a useful square.
    /// Never places marks and never reveals.
    var coachCellId: String? = nil
    /// Hints bought with Game Balls this level.
    var paidHints: Int = 0
    /// The one free hint per level.
    var freeHintUsed: Bool = false
    /// Cell the last hint highlighted; drives the gold pulse.
    var hintFlashCellId: String? = nil
    /// Transient banner text ("DEFENDER REVEALED!", "BLOWN ASSIGNMENT").
    var toastText: String? = nil
    var toastIsMistake: Bool = false
    /// Increments on each new toast so the UI can auto-dismiss it.
    var toastToken: Int = 0
    var isComplete: Bool = false
    var earnedStars: LevelStars = .none
}
