import Foundation

/// Pure logic for the simplified defensive puzzle. Three universal rules:
/// exactly one defender per row, one per column, and defenders never touch —
/// horizontally, vertically, or diagonally. No UI, no state.
///
/// The player performs every deduction on the board. The engine never places
/// X marks and never cascades: at most ONE defender reveals per player action,
/// and only when the player's OWN marks close a row or column onto its true
/// solution. Boards start clean — there are no pre-filled X clues.
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

    /// Cells that provably hide no defender because of the revealed defense:
    /// every cell sharing a row, column, or neighborhood with a revealed
    /// defender. The engine uses these only to evaluate contradictions and
    /// hint targets — it never draws them, and a reveal never credits them.
    static func impossibleCells(_ puzzle: PuzzleDefinition, revealed: [String: String]) -> Set<String> {
        var impossible: Set<String> = []
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

    /// The single reveal check, run after every player action. Returns at most
    /// one reveal: the first row or column (reading order) where the player's
    /// OWN X marks leave exactly one open cell, that cell is the stored
    /// solution, and at least one of the player's own X marks sits in that
    /// line (always true now that there are no starting clues, but kept as a
    /// guard).
    ///
    /// Revealed defenders are INFORMATION ONLY here: the engine does not credit
    /// their rows, columns, or neighbors as blocked. The player must personally
    /// X those squares before a line can close — internal knowledge about the
    /// geometry of revealed defenders never triggers a reveal by itself, and
    /// no hidden starting eliminations help the player.
    static func forcedReveal(
        _ puzzle: PuzzleDefinition,
        revealed: [String: String],
        marks: Set<String>
    ) -> (cell: String, kind: String)? {
        // Only what the player can SEE as blocked counts: their own X marks.
        let blocked = marks
        let size = puzzle.gridSize

        let lines: [[String]] =
            (0..<size).map { row in (0..<size).map { cellId(row: row, column: $0) } }
            + (0..<size).map { column in (0..<size).map { cellId(row: $0, column: column) } }

        for line in lines {
            guard !line.contains(where: { revealed[$0] != nil }) else { continue }
            let remaining = line.filter { !blocked.contains($0) && revealed[$0] == nil }
            guard remaining.count == 1 else { continue }
            let cell = remaining[0]
            guard let kind = puzzle.solution[cell] else { continue }
            guard line.contains(where: { marks.contains($0) }) else { continue }
            return (cell, kind)
        }
        return nil
    }

    /// True when a player X mark sits on a hidden defender, making some row or
    /// column impossible to satisfy. The player is never told WHICH mark is wrong.
    ///
    /// Unlike the reveal check, this MAY use the geometry of revealed defenders:
    /// if the remaining open cells of a line are all provably impossible (shared
    /// row, column, or neighborhood with a revealed defender), then any player
    /// mark covering the line's last viable cell is a genuine contradiction.
    /// When this returns true, a player mark is always sitting on a defender.
    static func hasContradiction(
        _ puzzle: PuzzleDefinition,
        revealed: [String: String],
        marks: Set<String>
    ) -> Bool {
        let blocked = impossibleCells(puzzle, revealed: revealed).union(marks)
        let size = puzzle.gridSize

        let lines: [[String]] =
            (0..<size).map { row in (0..<size).map { cellId(row: row, column: $0) } }
            + (0..<size).map { column in (0..<size).map { cellId(row: $0, column: column) } }

        for line in lines {
            guard !line.contains(where: { revealed[$0] != nil }) else { continue }
            let remaining = line.filter { !blocked.contains($0) && revealed[$0] == nil }
            if remaining.isEmpty { return true }
        }
        return false
    }

    /// The hint's target: ONE square the player can logically X. Prefers a mark
    /// that completes a reveal, then any provably-empty square tied to a revealed
    /// defender (its row, column, or neighbors — deductions the player should
    /// make themselves). The hint only highlights — the player still places the
    /// X themselves, and the reveal only comes once their marks close a line.
    static func hintXCell(
        _ puzzle: PuzzleDefinition,
        revealed: [String: String],
        marks: Set<String>
    ) -> String? {
        let impossible = impossibleCells(puzzle, revealed: revealed)
        var best: (cell: String, score: Int)?

        for cellId in puzzle.allCellIds {
            guard puzzle.solution[cellId] == nil,
                  revealed[cellId] == nil,
                  !marks.contains(cellId) else { continue }

            var trial = marks
            trial.insert(cellId)
            var score = 0
            if forcedReveal(puzzle, revealed: revealed, marks: trial) != nil {
                score = 2
            } else if impossible.contains(cellId) {
                score = 1
            }
            if score > (best?.score ?? -1) { best = (cellId, score) }
        }
        return best?.cell
    }

    // MARK: - Stars

    /// 3 stars for zero contradictions, 2 for one slip, 1 for anything messier.
    /// X marks themselves — right or wrong — never reduce stars.
    static func stars(mistakes: Int) -> LevelStars {
        switch mistakes {
        case 0: .three
        case 1: .two
        default: .one
        }
    }
}
