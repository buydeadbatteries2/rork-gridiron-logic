import Foundation

/// A fully handcrafted level: the play diagram for theme and context, plus the
/// hidden 5x5 defensive puzzle — solution cells, Coverage Zones, and any
/// defenders already revealed when the snap happens. Boards start clean: every
/// X on the field was placed by the player.
nonisolated struct PuzzleDefinition: Sendable, Hashable {
    let levelNumber: Int
    let play: OffensivePlay
    /// The grid is gridSize x gridSize; every Stadium 1 puzzle is 5.
    let gridSize: Int
    /// Cell id -> defender kind id. The unique correct defense.
    let solution: [String: String]
    /// Cell id -> Coverage Zone index (0–4). Every cell belongs to exactly one
    /// zone, every zone hides exactly one defender, and zones are the puzzle's
    /// visible structure — never X marks.
    let zoneOf: [String: Int]
    /// Defenders on the board when the play starts: cell id -> kind id.
    let startingRevealed: [String: String]
    /// Cost in Game Balls for hints after the free one.
    let hintCost: Int

    /// Every cell id in reading order: deep to shallow, then left to right.
    var allCellIds: [String] {
        (0..<gridSize).flatMap { row in
            (0..<gridSize).map { column in PuzzleEngine.cellId(row: row, column: column) }
        }
    }

    /// The correct defender for a cell, whether still hidden or pre-revealed.
    func solutionKind(inCellWithID id: String) -> String? {
        solution[id] ?? startingRevealed[id]
    }
}
