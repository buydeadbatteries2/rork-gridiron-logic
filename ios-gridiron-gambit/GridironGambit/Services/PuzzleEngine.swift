import Foundation

/// Pure logic for the defensive puzzle. The four permanent rules:
/// exactly one defender per Coverage Zone, one per row, one per column, and
/// defenders never touch — horizontally, vertically, or diagonally.
/// No UI, no state.
///
/// The player performs every deduction on the board. The engine never places
/// X marks and never cascades: at most ONE defender reveals per player action,
/// and only when the player's OWN marks close a row, column, or Coverage Zone
/// onto its true solution. Boards start clean — there are no pre-filled X
/// clues; Coverage Zones are puzzle structure, never marks.
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

    // MARK: - Coverage Zones

    /// The puzzle's Coverage Zones as lines of cell ids in reading order —
    /// exactly one line per zone, every cell in exactly one line.
    static func coverageZoneLines(_ puzzle: PuzzleDefinition) -> [[String]] {
        let size = puzzle.gridSize
        var zones: [[String]] = Array(repeating: [], count: size)
        for cellId in puzzle.allCellIds {
            if let zone = puzzle.zoneOf[cellId], zone >= 0, zone < size {
                zones[zone].append(cellId)
            }
        }
        return zones
    }

    /// Rows, then columns, then Coverage Zones — the three kinds of "lines"
    /// whose last open square can force a reveal.
    private static func allLines(_ puzzle: PuzzleDefinition) -> [[String]] {
        let size = puzzle.gridSize
        return (0..<size).map { row in (0..<size).map { cellId(row: row, column: $0) } }
            + (0..<size).map { column in (0..<size).map { cellId(row: $0, column: column) } }
            + coverageZoneLines(puzzle)
    }

    // MARK: - Full board consistency (contradiction safety net)

    /// Every complete defense that satisfies all FOUR rules, contains every
    /// visible revealed defender, and does not sit on any of the player's X
    /// marks. Brute-forced over at most 5! placements — cheap on a 5x5 board.
    ///
    /// - Empty result = the visible state is contradictory (blown assignment).
    /// - The stored solution is always included while the state is consistent,
    ///   so any cell agreed on by ALL remaining solutions is provably correct.
    static func remainingSolutions(
        _ puzzle: PuzzleDefinition,
        revealed: [String: String],
        marks: Set<String>
    ) -> [[String: String]] {
        let size = puzzle.gridSize
        let zoneOfCell: [String: Int] = Dictionary(
            uniqueKeysWithValues: puzzle.allCellIds.compactMap { id in
                puzzle.zoneOf[id].map { (id, $0) }
            }
        )
        var results: [[String: String]] = []
        var columns: [Int] = []
        var usedColumns = Array(repeating: false, count: size)
        var usedZones = Array(repeating: false, count: size)

        func backtrack(_ row: Int) {
            if row == size {
                var defense: [String: String] = [:]
                for r in 0..<size {
                    let id = cellId(row: r, column: columns[r])
                    guard let kind = puzzle.solution[id] else { return }
                    guard !marks.contains(id) else { return }
                    defense[id] = kind
                }
                results.append(defense)
                return
            }
            for column in 0..<size {
                guard !usedColumns[column] else { continue }
                if row > 0, abs(columns[row - 1] - column) < 2 { continue }
                guard let zone = zoneOfCell[cellId(row: row, column: column)],
                      !usedZones[zone] else { continue }

                usedColumns[column] = true
                usedZones[zone] = true
                columns.append(column)
                backtrack(row + 1)
                columns.removeLast()
                usedZones[zone] = false
                usedColumns[column] = false
            }
        }

        backtrack(0)
        return results
    }

    // MARK: - Derived board state

    /// Cells that provably hide no defender: every cell sharing a row, column,
    /// neighborhood, or COVERAGE ZONE with a revealed defender. The engine uses
    /// these only to evaluate hint targets — it never draws them, and a reveal
    /// never credits them as blocked. The player must personally X them.
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
        for line in coverageZoneLines(puzzle) where line.contains(where: { revealed[$0] != nil }) {
            // A zone that already shows its defender hides no other defenders.
            impossible.formUnion(line)
        }
        for revealedCell in revealed.keys { impossible.remove(revealedCell) }
        return impossible
    }

    /// The single reveal check, run after every player action. Returns at most
    /// one reveal: the first row, column, or Coverage Zone (reading order)
    /// where the player's OWN X marks leave exactly one open cell, that cell is
    /// the stored solution, and at least one of the player's own X marks sits
    /// in that line.
    ///
    /// Revealed defenders and their geometry are INFORMATION ONLY here — the
    /// engine does not credit their rows, columns, neighbors, or zones as
    /// blocked. The player must personally X those squares before a line can
    /// close. A line whose defender is already visible is skipped.
    static func forcedReveal(
        _ puzzle: PuzzleDefinition,
        revealed: [String: String],
        marks: Set<String>
    ) -> (cell: String, kind: String)? {
        let blocked = marks

        for line in allLines(puzzle) {
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

    /// True when the player's marks have made the visible state impossible:
    /// NO complete defense satisfies the four rules alongside the revealed
    /// defenders and the marks. The player is never told WHICH mark is wrong.
    static func hasContradiction(
        _ puzzle: PuzzleDefinition,
        revealed: [String: String],
        marks: Set<String>
    ) -> Bool {
        remainingSolutions(puzzle, revealed: revealed, marks: marks).isEmpty
    }

    /// The hint's target: ONE square the player can logically X. Prefers a
    /// mark that completes a reveal, then a provably-empty square (row,
    /// column, neighborhood, or zone of a revealed defender), then any square
    /// eliminated by the full four-rule logic. NEVER a hidden defender — every
    /// candidate is already a non-solution square. The hint only highlights —
    /// the player still places the X themselves, and the reveal only comes
    /// once their marks close a line.
    static func hintXCell(
        _ puzzle: PuzzleDefinition,
        revealed: [String: String],
        marks: Set<String>
    ) -> String? {
        let impossible = impossibleCells(puzzle, revealed: revealed)
        let possible = Set(
            remainingSolutions(puzzle, revealed: revealed, marks: marks)
                .flatMap { $0.keys }
        )
        var best: (cell: String, score: Int)?

        for cellId in puzzle.allCellIds {
            guard puzzle.solution[cellId] == nil,
                  revealed[cellId] == nil,
                  !marks.contains(cellId) else { continue }

            var trial = marks
            trial.insert(cellId)
            var score = 0
            if forcedReveal(puzzle, revealed: revealed, marks: trial) != nil {
                score = 3
            } else if impossible.contains(cellId) {
                score = 2
            } else if !possible.contains(cellId) {
                score = 1
            }
            if score > (best?.score ?? -1) { best = (cellId, score) }
        }
        return best?.cell
    }

    // MARK: - Stars

    /// Stars equal the downs remaining on a successful completion:
    /// 3 downs = 3 stars, 2 = 2 stars, 1 = 1 star.
    static func stars(down: Int) -> LevelStars {
        switch down {
        case 3: .three
        case 2: .two
        default: .one
        }
    }
}
