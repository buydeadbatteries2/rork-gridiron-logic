import Foundation

/// Pure logic for the simplified defensive puzzle. Three universal rules:
/// exactly one defender per row, one per column, and defenders never touch —
/// horizontally, vertically, or diagonally. No UI, no state.
nonisolated enum PuzzleEngine {

    // MARK: - Cell addressing

    /// Stable cell id for a grid coordinate, e.g. "cell-0-3".
    static func cellId(row: Int, column: Int) -> String {
        "cell-\(row)-\(column)"
    }

    static func row(ofCellId id: String) -> Int? {
        coordinates(ofCellId: id)?.row
    }

    static func column(ofCellId id: String) -> Int? {
        coordinates(ofCellId: id)?.column
    }

    private static func coordinates(ofCellId id: String) -> (row: Int, column: Int)? {
        let parts = id.split(separator: "-")
        guard parts.count == 3, parts[0] == "cell",
              let row = Int(parts[1]), let column = Int(parts[2]) else { return nil }
        return (row, column)
    }

    /// True when two cells touch horizontally, vertically, or diagonally.
    static func areNeighbors(_ lhs: String, _ rhs: String) -> Bool {
        guard lhs != rhs,
              let a = coordinates(ofCellId: lhs),
              let b = coordinates(ofCellId: rhs) else { return false }
        return abs(a.row - b.row) <= 1 && abs(a.column - b.column) <= 1
    }

    /// Sorts cell ids in reading order: deep to shallow, then left to right.
    static func sortedReadingOrder(_ ids: some Sequence<String>) -> [String] {
        ids.sorted { lhs, rhs in
            let left = coordinates(ofCellId: lhs) ?? (row: 0, column: 0)
            let right = coordinates(ofCellId: rhs) ?? (row: 0, column: 0)
            return left.row == right.row ? left.column < right.column : left.row < right.row
        }
    }

    // MARK: - Derived board state

    /// Cells that provably hide no defender: starting X clues plus every cell
    /// sharing a row, column, or neighborhood with a revealed defender.
    static func impossibleCells(_ puzzle: PuzzleDefinition, revealed: [String: String]) -> Set<String> {
        var impossible = puzzle.startingX
        let size = puzzle.gridSize

        for revealedCell in revealed.keys {
            guard let r = row(ofCellId: revealedCell), let c = column(ofCellId: revealedCell) else { continue }
            for clearRow in 0..<size { impossible.insert(cellId(row: clearRow, column: c)) }
            for clearColumn in 0..<size { impossible.insert(cellId(row: r, column: clearColumn)) }
            for dr in -1...1 {
                for dc in -1...1 {
                    let neighborRow = r + dr
                    let neighborColumn = c + dc
                    guard neighborRow >= 0, neighborRow < size, neighborColumn >= 0, neighborColumn < size else { continue }
                    impossible.insert(cellId(row: neighborRow, column: neighborColumn))
                }
            }
        }
        for revealedCell in revealed.keys { impossible.remove(revealedCell) }
        return impossible
    }

    /// The Smart Reveal trigger: rows or columns with exactly one unblocked
    /// cell left. Player X marks count as blocks, but a defender is only
    /// auto-revealed when the remaining cell truly is a solution cell — a mark
    /// on the real solution never causes an unfair reveal.
    static func forcedReveals(
        _ puzzle: PuzzleDefinition,
        revealed: [String: String],
        marks: Set<String>
    ) -> [String: String] {
        var blocked = impossibleCells(puzzle, revealed: revealed).union(marks)
        for cellId in revealed.keys { blocked.remove(cellId) }

        var byRow: [Int: [String]] = [:]
        var byColumn: [Int: [String]] = [:]
        for cellId in puzzle.allCellIds where !blocked.contains(cellId) && revealed[cellId] == nil {
            if let r = row(ofCellId: cellId) { byRow[r, default: []].append(cellId) }
            if let c = column(ofCellId: cellId) { byColumn[c, default: []].append(cellId) }
        }

        var forced: [String: String] = [:]
        for group in [byRow, byColumn] {
            for (_, cells) in group where cells.count == 1 {
                let cellId = cells[0]
                if let kind = puzzle.solution[cellId] {
                    forced[cellId] = kind
                }
            }
        }
        return forced
    }

    /// The hint's preferred move: a correct X (a cell that provably holds no
    /// defender and isn't marked yet) chosen to unlock the most Smart Reveals.
    /// `marks` should include the session's locked mistakes.
    static func hintXCell(
        _ puzzle: PuzzleDefinition,
        revealed: [String: String],
        marks: Set<String>
    ) -> String? {
        let impossible = impossibleCells(puzzle, revealed: revealed)
        var bestCell: String?
        var bestGain = -1

        for cellId in puzzle.allCellIds {
            guard puzzle.solution[cellId] == nil,
                  revealed[cellId] == nil,
                  !marks.contains(cellId),
                  !impossible.contains(cellId) else { continue }

            var trial = marks
            trial.insert(cellId)
            let gain = forcedReveals(puzzle, revealed: revealed, marks: trial).count
            if gain > bestGain {
                bestGain = gain
                bestCell = cellId
            }
        }
        return bestCell
    }

    /// When every unmarked cell could still hide a defender, the hint falls
    /// back to revealing the next hidden solution defender in reading order.
    static func hintRevealCell(_ puzzle: PuzzleDefinition, revealed: [String: String]) -> String? {
        puzzle.allCellIds.first { puzzle.solution[$0] != nil && revealed[$0] == nil }
    }

    // MARK: - Stars

    /// 3 stars for zero failed reveals, 2 for one slip, 1 for anything messier.
    /// X marks — right or wrong — never reduce stars.
    static func stars(wrongReveals: Int) -> LevelStars {
        switch wrongReveals {
        case 0: .three
        case 1: .two
        default: .one
        }
    }
}
