import XCTest
@testable import GridironGambit

/// Verifies every Stadium 1 puzzle under the three universal rules — one
/// defender per row, one per column, defenders never touch. Each puzzle must
/// have EXACTLY ONE solution consistent with its starting X clues and
/// revealed defenders, and it must match the stored solution.
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

    func testStartingXCluesNeverCoverSolutionOrRevealedCells() {
        for puzzle in Puzzles.all {
            for cellId in puzzle.startingX {
                XCTAssertNil(
                    puzzle.solution[cellId],
                    "Level \(puzzle.levelNumber): starting X sits on a solution cell \(cellId)"
                )
                XCTAssertNil(
                    puzzle.startingRevealed[cellId],
                    "Level \(puzzle.levelNumber): starting X sits on a revealed defender \(cellId)"
                )
            }
            for (cellId, kind) in puzzle.startingRevealed {
                XCTAssertEqual(
                    puzzle.solution[cellId],
                    kind,
                    "Level \(puzzle.levelNumber): revealed defender contradicts solution at \(cellId)"
                )
            }
        }
    }

    // MARK: - Uniqueness (brute force)

    func testEveryPuzzleHasExactlyOneSolution() {
        for puzzle in Puzzles.all {
            let solutions = bruteForcePositionSets(puzzle)
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

    /// Enumerates every placement satisfying the three universal rules,
    /// the starting X clues, and the starting revealed defenders.
    private func bruteForcePositionSets(_ puzzle: PuzzleDefinition) -> [[Int]] {
        let size = puzzle.gridSize
        var revealedByRow: [Int: Int] = [:]
        for cellId in puzzle.startingRevealed.keys {
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
                if puzzle.startingX.contains(cellId) { continue }
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
        XCTAssertEqual(PuzzleEngine.stars(wrongReveals: 0), .three)
        XCTAssertEqual(PuzzleEngine.stars(wrongReveals: 1), .two)
        XCTAssertEqual(PuzzleEngine.stars(wrongReveals: 2), .one)
        XCTAssertEqual(PuzzleEngine.stars(wrongReveals: 5), .one)
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

    func testForcedRevealFiresWhenRowHasOneCandidateLeft() {
        // Block every cell of row 0 except the solution cell cell-0-0.
        let blocked: Set<String> = Set((1...4).map { PuzzleEngine.cellId(row: 0, column: $0) })
        let puzzle = makeTestPuzzle(startX: blocked)

        let forced = PuzzleEngine.forcedReveals(puzzle, revealed: [:], marks: [])
        XCTAssertEqual(forced["cell-0-0"], "cb")
    }

    func testPlayerMarkOnSolutionCellNeverCausesUnfairReveal() {
        // Row 0: player wrongly X'd the real solution cell, leaving cell-0-1 open.
        let blocked: Set<String> = Set((2...4).map { PuzzleEngine.cellId(row: 0, column: $0) })
        let puzzle = makeTestPuzzle(startX: blocked)

        let forced = PuzzleEngine.forcedReveals(puzzle, revealed: [:], marks: ["cell-0-0"])
        XCTAssertNil(forced["cell-0-1"], "The remaining cell is not the solution — no auto-reveal")
    }

    func testHintTargetsAreSensible() {
        for puzzle in Puzzles.all {
            let revealed = puzzle.startingRevealed
            if let xCell = PuzzleEngine.hintXCell(puzzle, revealed: revealed, marks: []) {
                XCTAssertNil(puzzle.solution[xCell], "Level \(puzzle.levelNumber): hint X'd a solution cell")
                XCTAssertFalse(puzzle.startingX.contains(xCell), "Level \(puzzle.levelNumber): hint re-marked a clue")
            }
            if let revealCell = PuzzleEngine.hintRevealCell(puzzle, revealed: revealed) {
                XCTAssertNotNil(puzzle.solution[revealCell], "Level \(puzzle.levelNumber): hint reveal is not a solution cell")
            }
        }
    }

    func testHintCompletesLevelOneByOne() {
        let puzzle = Puzzles.puzzle(for: 1)!
        var revealed = puzzle.startingRevealed
        var marks: Set<String> = []

        while revealed.count < puzzle.solution.count {
            if let xCell = PuzzleEngine.hintXCell(puzzle, revealed: revealed, marks: marks) {
                marks.insert(xCell)
                // Smart Reveal may cascade.
                var forced = PuzzleEngine.forcedReveals(puzzle, revealed: revealed, marks: marks)
                while let cellId = PuzzleEngine.sortedReadingOrder(forced.keys).first,
                      let kind = forced[cellId] {
                    revealed[cellId] = kind
                    forced = PuzzleEngine.forcedReveals(puzzle, revealed: revealed, marks: marks)
                }
            } else if let revealCell = PuzzleEngine.hintRevealCell(puzzle, revealed: revealed),
                      let kind = puzzle.solution[revealCell] {
                revealed[revealCell] = kind
            } else {
                XCTFail("Hint loop stalled on level 1")
                return
            }
        }
        XCTAssertEqual(revealed, puzzle.solution)
    }

    // MARK: - Fixtures

    /// A 5x5 puzzle with defenders on (0,0), (1,2), (2,4), (3,1), (4,3).
    private func makeTestPuzzle(startX: Set<String> = []) -> PuzzleDefinition {
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
            startingX: startX,
            startingRevealed: [:],
            hintCost: 25
        )
    }
}
