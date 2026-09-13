import XCTest
@testable import GridironGambit

/// Verifies every Stadium 1 puzzle under the three universal rules — one
/// defender per row, one per column, defenders never touch. Boards start
/// clean: no pre-filled X marks exist. Each puzzle must have EXACTLY ONE
/// solution consistent with its visible starting revealed defenders, and it
/// must match the stored solution.
final class PuzzleTests: XCTestCase {

    // MARK: - Data integrity

    func testAllStadiumOneLevelsHavePuzzles() {
        for levelNumber in 1...15 {
            let puzzle = Puzzles.puzzle(for: levelNumber)
            XCTAssertNotNil(puzzle, "Level \(levelNumber) has no puzzle")
            XCTAssertEqual(puzzle?.levelNumber, levelNumber)
        }
    }

    func testGridIsFiveByFive() {
        for puzzle in Puzzles.all {
            XCTAssertEqual(puzzle.gridSize, 5, "Level \(puzzle.levelNumber): Stadium 1 is 5x5 only")
            XCTAssertEqual(puzzle.allCellIds.count, 25)
        }
    }

    func testSolutionHasOneDefenderPerRowAndColumn() {
        for puzzle in Puzzles.all {
            XCTAssertEqual(puzzle.solution.count, 5, "Level \(puzzle.levelNumber): five hidden defenders")

            var rows: Set<Int> = []
            var columns: Set<Int> = []
            for cellId in puzzle.solution.keys {
                guard let row = PuzzleEngine.row(ofCellId: cellId),
                      let column = PuzzleEngine.column(ofCellId: cellId) else {
                    XCTFail("Level \(puzzle.levelNumber): unparsable cell id \(cellId)")
                    continue
                }
                rows.insert(row)
                columns.insert(column)
            }
            XCTAssertEqual(rows.count, 5, "Level \(puzzle.levelNumber): one defender per row")
            XCTAssertEqual(columns.count, 5, "Level \(puzzle.levelNumber): one defender per column")
        }
    }

    func testDefendersNeverTouch() {
        for puzzle in Puzzles.all {
            let cellIds = Array(puzzle.solution.keys)
            for i in cellIds.indices {
                for j in cellIds.indices where i < j {
                    XCTAssertFalse(
                        PuzzleEngine.areNeighbors(cellIds[i], cellIds[j]),
                        "Level \(puzzle.levelNumber): defenders at \(cellIds[i]) and \(cellIds[j]) touch"
                    )
                }
            }
        }
    }

    func testHidesTwoCornersTwoLinebackersOneSafety() {
        for puzzle in Puzzles.all {
            var counts: [String: Int] = [:]
            for kind in puzzle.solution.values {
                counts[kind, default: 0] += 1
            }
            XCTAssertEqual(counts, ["cb": 2, "lb": 2, "s": 1], "Level \(puzzle.levelNumber)")
        }
    }

    func testStartingRevealedDefendersMatchSolutionAndNeverTouch() {
        for puzzle in Puzzles.all {
            for (cellId, kind) in puzzle.startingRevealed {
                XCTAssertEqual(
                    puzzle.solution[cellId],
                    kind,
                    "Level \(puzzle.levelNumber): revealed defender contradicts solution at \(cellId)"
                )
            }
            let cells = Array(puzzle.startingRevealed.keys)
            for i in cells.indices {
                for j in cells.indices where i < j {
                    XCTAssertFalse(
                        PuzzleEngine.areNeighbors(cells[i], cells[j]),
                        "Level \(puzzle.levelNumber): starting reveals at \(cells[i]) and \(cells[j]) touch"
                    )
                }
            }
        }
    }

    // MARK: - Uniqueness (brute force)

    func testEveryPuzzleHasExactlyOneSolution() {
        for puzzle in Puzzles.all {
            // Level 1 intentionally starts with a single reveal; the guided
            // tutorial drives the safety reveal before free play begins.
            var revealed = puzzle.startingRevealed
            if puzzle.levelNumber == 1 {
                XCTAssertEqual(
                    bruteForcePositionSets(puzzle, revealed: revealed).count,
                    2,
                    "Level 1 should present exactly two candidate defenses before the tutorial reveal"
                )
                revealed["cell-1-3"] = "s"
            }
            let solutions = bruteForcePositionSets(puzzle, revealed: revealed)
            XCTAssertEqual(
                solutions.count,
                1,
                "Level \(puzzle.levelNumber) has \(solutions.count) solutions: \(solutions)"
            )
            guard solutions.count == 1 else { continue }

            var computed: [String: String] = [:]
            for row in 0..<puzzle.gridSize {
                let cellId = PuzzleEngine.cellId(row: row, column: solutions[0][row])
                guard let kind = puzzle.solution[cellId] else {
                    XCTFail("Level \(puzzle.levelNumber): the unique solution differs from the stored one")
                    break
                }
                computed[cellId] = kind
            }
            XCTAssertEqual(
                computed,
                puzzle.solution,
                "Level \(puzzle.levelNumber): the unique solution differs from the stored one"
            )
        }
    }

    /// Enumerates every placement satisfying the three universal rules and the
    /// given VISIBLE revealed defenders. No starting X clues exist anymore.
    private func bruteForcePositionSets(
        _ puzzle: PuzzleDefinition,
        revealed: [String: String]
    ) -> [[Int]] {
        let size = puzzle.gridSize
        var revealedByRow: [Int: Int] = [:]
        for cellId in revealed.keys {
            if let row = PuzzleEngine.row(ofCellId: cellId),
               let column = PuzzleEngine.column(ofCellId: cellId) {
                revealedByRow[row] = column
            }
        }

        var result: [[Int]] = []
        var columns: [Int] = []

        func backtrack(_ row: Int) {
            if row == size {
                result.append(columns)
                return
            }
            for column in 0..<size {
                let cellId = PuzzleEngine.cellId(row: row, column: column)
                if let fixed = revealedByRow[row], fixed != column { continue }
                if row > 0, abs(column - columns[row - 1]) <= 1 { continue }
                columns.append(column)
                backtrack(row + 1)
                columns.removeLast()
            }
        }

        backtrack(0)
        return result
    }

    // MARK: - Engine behavior

    func testStars() {
        XCTAssertEqual(PuzzleEngine.stars(mistakes: 0), .three)
        XCTAssertEqual(PuzzleEngine.stars(mistakes: 1), .two)
        XCTAssertEqual(PuzzleEngine.stars(mistakes: 2), .one)
        XCTAssertEqual(PuzzleEngine.stars(mistakes: 5), .one)
    }

    func testRevealedDefenderEliminatesRowColumnAndNeighbors() {
        let puzzle = makeTestPuzzle()

        let impossible = PuzzleEngine.impossibleCells(puzzle, revealed: ["cell-2-4": "lb"])
        // Same row
        XCTAssertTrue(impossible.contains("cell-2-0"))
        // Same column
        XCTAssertTrue(impossible.contains("cell-0-4"))
        // Diagonal neighbor
        XCTAssertTrue(impossible.contains("cell-1-3"))
        // Unrelated cell stays open
        XCTAssertFalse(impossible.contains("cell-0-0"))
        // The revealed cell itself is not "impossible"
        XCTAssertFalse(impossible.contains("cell-2-4"))
    }

    /// With zero player marks the board is static: nothing may reveal at the
    /// snap, on any level, no matter how the revealed defenders sit.
    func testNoLevelRevealsWithoutPlayerMarks() {
        for puzzle in Puzzles.all {
            XCTAssertNil(
                PuzzleEngine.forcedReveal(puzzle, revealed: puzzle.startingRevealed, marks: []),
                "Level \(puzzle.levelNumber): the game tried to play itself at the snap"
            )
        }
    }

    /// A revealed defender is INFORMATION ONLY: the engine must not credit its
    /// row, column, or neighbors as blocked. The reveal waits until the player
    /// has personally X'd every other square in the line.
    func testRevealWaitsForPlayerToMarkRevealedDefendersNeighbors() {
        let puzzle = makeTestPuzzle()
        // Linebacker revealed at (2,4). Its diagonal neighbors (1,3)/(1,4) and
        // the rest of its row/column must stay OPEN until the player X's them.
        let revealed = ["cell-2-4": "lb"]

        // Row 1 hides the safety at (1,2). The player X'd (1,0) — but (1,1) and
        // (1,4) are still open on the board, so nothing may reveal yet, even
        // though the engine internally knows (1,3)/(1,4) are impossible.
        XCTAssertNil(
            PuzzleEngine.forcedReveal(puzzle, revealed: revealed, marks: ["cell-1-0"]),
            "Reveal fired from internal knowledge — the player hasn't finished the elimination"
        )
        XCTAssertNil(
            PuzzleEngine.forcedReveal(puzzle, revealed: revealed, marks: ["cell-1-0", "cell-1-1"]),
            "Still one open square left for the player to block"
        )

        // The revealed defender's own row never reveals again, no matter what.
        XCTAssertNil(
            PuzzleEngine.forcedReveal(puzzle, revealed: revealed, marks: ["cell-2-0", "cell-2-1", "cell-2-2", "cell-2-3"]),
            "A line with a revealed defender cannot reveal a second one"
        )

        // Now the player closes row 1 personally → the safety reveals.
        let forced = PuzzleEngine.forcedReveal(
            puzzle,
            revealed: revealed,
            marks: ["cell-1-0", "cell-1-1", "cell-1-4"]
        )
        XCTAssertEqual(forced?.cell, "cell-1-2")
        XCTAssertEqual(forced?.kind, "s")
    }

    func testNoRevealWhenRemainingCellIsNotTheSolution() {
        let puzzle = makeTestPuzzle()

        // Row 0 hides the corner at (0,0). The player blocked three squares,
        // leaving two open — nothing to reveal yet.
        let partial: Set<String> = ["cell-0-2", "cell-0-3", "cell-0-4"]
        XCTAssertNil(
            PuzzleEngine.forcedReveal(puzzle, revealed: [:], marks: partial),
            "Two cells still open — nothing to reveal"
        )

        // Closing the row onto a non-solution cell never reveals.
        let wrongClosure: Set<String> = ["cell-0-0", "cell-0-1", "cell-0-2", "cell-0-3"]
        XCTAssertNil(
            PuzzleEngine.forcedReveal(puzzle, revealed: [:], marks: wrongClosure),
            "The remaining cell is not the solution — never reveal"
        )

        // Closing the row onto the true solution reveals the corner.
        let forced = PuzzleEngine.forcedReveal(
            puzzle,
            revealed: [:],
            marks: ["cell-0-1", "cell-0-2", "cell-0-3", "cell-0-4"]
        )
        XCTAssertEqual(forced?.cell, "cell-0-0")
        XCTAssertEqual(forced?.kind, "cb")
    }

    func testContradictionDetectedWhenPlayerBlocksADefender() {
        let puzzle = makeTestPuzzle()

        XCTAssertFalse(
            PuzzleEngine.hasContradiction(
                puzzle,
                revealed: [:],
                marks: ["cell-0-1", "cell-0-2", "cell-0-3", "cell-0-4"]
            ),
            "One open cell left — contradictory but not impossible"
        )
        XCTAssertTrue(
            PuzzleEngine.hasContradiction(
                puzzle,
                revealed: [:],
                marks: ["cell-0-0", "cell-0-1", "cell-0-2", "cell-0-3", "cell-0-4"]
            ),
            "Every row-0 cell is blocked — a mark must be sitting on the defender"
        )
    }

    func testHintHighlightsCorrectSquares() {
        for puzzle in Puzzles.all {
            let revealed = puzzle.startingRevealed
            for marked: Set<String> in [[], ["cell-0-0"]] {
                if let cell = PuzzleEngine.hintXCell(puzzle, revealed: revealed, marks: marked) {
                    XCTAssertNil(puzzle.solution[cell], "Level \(puzzle.levelNumber): hint pointed at a defender")
                    XCTAssertFalse(revealed.keys.contains(cell), "Level \(puzzle.levelNumber): hint re-marked a reveal")
                    XCTAssertFalse(marked.contains(cell), "Level \(puzzle.levelNumber): hint re-marked an X")
                }
            }
        }
    }

    /// Simulates a player who only ever follows hints: mark the hinted square,
    /// let the engine evaluate once (single reveal, no chains). Must finish every level.
    func testHintGuidedPlayCompletesEveryLevel() {
        for puzzle in Puzzles.all {
            var revealed = puzzle.startingRevealed
            var marks: Set<String> = []
            var guardCounter = 0

            while revealed.count < puzzle.solution.count {
                guardCounter += 1
                XCTAssertLessThan(guardCounter, 60, "Level \(puzzle.levelNumber): hint-guided play stalled")

                guard let cell = PuzzleEngine.hintXCell(puzzle, revealed: revealed, marks: marks) else {
                    XCTFail("Level \(puzzle.levelNumber): hint found no square")
                    break
                }
                marks.insert(cell)

                if let forced = PuzzleEngine.forcedReveal(puzzle, revealed: revealed, marks: marks) {
                    revealed[forced.cell] = forced.kind
                }
            }
            XCTAssertEqual(revealed, puzzle.solution, "Level \(puzzle.levelNumber)")
        }
    }

    // MARK: - Fixtures

    /// A 5x5 puzzle with defenders on (0,0), (1,2), (2,4), (3,1), (4,3).
    private func makeTestPuzzle() -> PuzzleDefinition {
        let solution: [String: String] = [
            "cell-0-0": "cb",
            "cell-1-2": "s",
            "cell-2-4": "lb",
            "cell-3-1": "lb",
            "cell-4-3": "cb",
        ]
        return PuzzleDefinition(
            levelNumber: 99,
            play: OffensivePlay(
                situation: PlaySituation(
                    levelNumber: 99,
                    down: "1st & 10",
                    ballOn: "Ball on 25",
                    playClock: 10,
                    playName: "Test Play"
                ),
                markers: [],
                routes: [],
                lineOfScrimmage: 0.62
            ),
            gridSize: 5,
            solution: solution,
            startingRevealed: [:],
            hintCost: 25
        )
    }
}
