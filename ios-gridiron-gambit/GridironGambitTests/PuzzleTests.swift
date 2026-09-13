import XCTest
@testable import GridironGambit

/// Verifies every Stadium 1 puzzle under the four permanent rules — one
/// defender per Coverage Zone, one per row, one per column, defenders never
/// touch. Boards start clean: no pre-filled X marks exist. Each puzzle must
/// have EXACTLY ONE solution consistent with its visible state (Coverage
/// Zones + starting revealed defenders), and it must match the stored one.
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

    func testCoverageZonesCoverEveryCellExactlyOnce() {
        for puzzle in Puzzles.all {
            XCTAssertEqual(
                puzzle.zoneOf.count, 25,
                "Level \(puzzle.levelNumber): every cell must belong to exactly one zone"
            )
            let zoneSizes = Dictionary(grouping: puzzle.zoneOf.values, by: { $0 }).mapValues(\.count)
            XCTAssertEqual(
                Set(zoneSizes.keys), Set(0...4),
                "Level \(puzzle.levelNumber): exactly five zones"
            )
            for (zone, size) in zoneSizes {
                XCTAssertGreaterThanOrEqual(size, 3, "Level \(puzzle.levelNumber): zone \(zone) is too small")
            }

            for (zone, line) in PuzzleEngine.coverageZoneLines(puzzle).enumerated() {
                XCTAssertTrue(isContiguous(line), "Level \(puzzle.levelNumber): zone \(zone) is not contiguous")
                for row in 0..<puzzle.gridSize {
                    XCTAssertNotEqual(
                        Set(line), Set((0..<puzzle.gridSize).map { PuzzleEngine.cellId(row: row, column: $0) }),
                        "Level \(puzzle.levelNumber): zone \(zone) is a full row"
                    )
                }
                for column in 0..<puzzle.gridSize {
                    XCTAssertNotEqual(
                        Set(line), Set((0..<puzzle.gridSize).map { PuzzleEngine.cellId(row: $0, column: column) }),
                        "Level \(puzzle.levelNumber): zone \(zone) is a full column"
                    )
                }
            }
        }
    }

    func testEachZoneHidesExactlyOneSolutionDefender() {
        for puzzle in Puzzles.all {
            var perZone: [Int: Int] = [:]
            for cellId in puzzle.solution.keys {
                guard let zone = puzzle.zoneOf[cellId] else {
                    XCTFail("Level \(puzzle.levelNumber): solution cell \(cellId) has no zone")
                    continue
                }
                perZone[zone, default: 0] += 1
            }
            XCTAssertEqual(
                perZone, [0: 1, 1: 1, 2: 1, 3: 1, 4: 1],
                "Level \(puzzle.levelNumber): every zone must hold exactly one defender"
            )
        }
    }

    func testStartingRevealedDefendersMatchSolution() {
        for puzzle in Puzzles.all {
            for (cellId, kind) in puzzle.startingRevealed {
                XCTAssertEqual(
                    puzzle.solution[cellId],
                    kind,
                    "Level \(puzzle.levelNumber): revealed defender contradicts solution at \(cellId)"
                )
            }
        }
    }

    // MARK: - Uniqueness (brute force over the four rules)

    func testEveryPuzzleHasExactlyOneSolution() {
        for puzzle in Puzzles.all {
            let solutions = PuzzleEngine.remainingSolutions(puzzle, revealed: puzzle.startingRevealed, marks: [])
            XCTAssertEqual(
                solutions.count, 1,
                "Level \(puzzle.levelNumber) has \(solutions.count) solutions from its visible state"
            )
            XCTAssertEqual(
                solutions.first, puzzle.solution,
                "Level \(puzzle.levelNumber): the unique solution differs from the stored one"
            )
        }
    }

    func testMarkingAHiddenDefenderLeavesZeroSolutions() {
        for puzzle in Puzzles.all {
            guard let hiddenDefender = puzzle.solution.keys.first(where: { puzzle.startingRevealed[$0] == nil }) else {
                XCTFail("Level \(puzzle.levelNumber): no hidden defender")
                continue
            }
            XCTAssertTrue(
                PuzzleEngine.hasContradiction(puzzle, revealed: puzzle.startingRevealed, marks: [hiddenDefender]),
                "Level \(puzzle.levelNumber): X'ing a hidden defender must be a blown assignment"
            )
        }
    }

    // MARK: - Engine behavior

    func testStarsEqualDownsRemaining() {
        XCTAssertEqual(PuzzleEngine.stars(down: 3), .three)
        XCTAssertEqual(PuzzleEngine.stars(down: 2), .two)
        XCTAssertEqual(PuzzleEngine.stars(down: 1), .one)
        XCTAssertEqual(PuzzleEngine.stars(down: 0), .one)
    }

    func testRevealedDefenderEliminatesRowColumnNeighborsAndZone() {
        let puzzle = makeTestPuzzle()

        let impossible = PuzzleEngine.impossibleCells(puzzle, revealed: ["cell-2-4": "lb"])
        // Same row
        XCTAssertTrue(impossible.contains("cell-2-0"))
        // Same column
        XCTAssertTrue(impossible.contains("cell-0-4"))
        // Diagonal neighbor
        XCTAssertTrue(impossible.contains("cell-1-3"))
        // Zone-mates of the revealed defender
        XCTAssertTrue(impossible.contains("cell-2-2"))
        XCTAssertTrue(impossible.contains("cell-3-4"))
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
    /// row, column, neighbors, or zone as blocked. The reveal waits until the
    /// player has personally X'd every other square in the line.
    func testRevealWaitsForPlayerToMarkRevealedDefendersNeighbors() {
        let puzzle = makeTestPuzzle()
        // Linebacker revealed at (2,4). Its zone-mates and the rest of its
        // row/column must stay OPEN until the player X's them.
        let revealed = ["cell-2-4": "lb"]

        // Row 1 hides the safety at (1,2). The player X'd (1,0) — but (1,1),
        // (1,3) and (1,4) are still open on the board, so nothing may reveal.
        XCTAssertNil(
            PuzzleEngine.forcedReveal(puzzle, revealed: revealed, marks: ["cell-1-0"]),
            "Reveal fired from internal knowledge — the player hasn't finished the elimination"
        )
        XCTAssertNil(
            PuzzleEngine.forcedReveal(puzzle, revealed: revealed, marks: ["cell-1-0", "cell-1-1"]),
            "Still open squares left for the player to block"
        )

        // The revealed defender's own row never reveals again, no matter what.
        XCTAssertNil(
            PuzzleEngine.forcedReveal(
                puzzle,
                revealed: revealed,
                marks: ["cell-2-0", "cell-2-1", "cell-2-2", "cell-2-3"]
            ),
            "A line with a revealed defender cannot reveal a second one"
        )

        // Now the player closes row 1 personally → the safety reveals.
        let forced = PuzzleEngine.forcedReveal(
            puzzle,
            revealed: revealed,
            marks: ["cell-1-0", "cell-1-1", "cell-1-3", "cell-1-4"]
        )
        XCTAssertEqual(forced?.cell, "cell-1-2")
        XCTAssertEqual(forced?.kind, "s")
    }

    /// A zone whose defender is already revealed can never close again —
    /// even when the player has X'd every other square in it.
    func testZoneWithRevealedDefenderNeverRevealsAgain() {
        let puzzle = makeTestPuzzle()
        let revealed = ["cell-2-4": "lb"]
        // Zone C = (2,2),(2,3),(2,4),(3,2),(3,4). Every non-revealed square X'd.
        let marks: Set<String> = ["cell-2-2", "cell-2-3", "cell-3-2", "cell-3-4"]
        XCTAssertNil(
            PuzzleEngine.forcedReveal(puzzle, revealed: revealed, marks: marks),
            "A zone with a revealed defender cannot reveal a second one"
        )
    }

    /// A zone the player closes personally reveals its hidden defender.
    func testZoneClosureRevealsDefender() {
        let puzzle = makeTestPuzzle()
        let revealed = ["cell-2-4": "lb"]
        // Zone D = (2,0),(2,1),(3,0),(3,1),(4,0): X every square but (3,1).
        let marks: Set<String> = ["cell-2-0", "cell-2-1", "cell-3-0", "cell-4-0"]
        let forced = PuzzleEngine.forcedReveal(puzzle, revealed: revealed, marks: marks)
        XCTAssertEqual(forced?.cell, "cell-3-1")
        XCTAssertEqual(forced?.kind, "lb")
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
                XCTAssertFalse(
                    PuzzleEngine.hasContradiction(puzzle, revealed: revealed, marks: marks.union([cell])),
                    "Level \(puzzle.levelNumber): hint pointed at a blown assignment"
                )
                marks.insert(cell)

                if let forced = PuzzleEngine.forcedReveal(puzzle, revealed: revealed, marks: marks) {
                    revealed[forced.cell] = forced.kind
                }
            }
            XCTAssertEqual(revealed, puzzle.solution, "Level \(puzzle.levelNumber)")
        }
    }

    /// The guided tutorial: the four scripted taps teach zone → row/column →
    /// no-touch, place ZERO automatic marks, and the final tap triggers exactly
    /// one reveal through the normal engine path.
    func testLevelOneTutorialSequenceEndsInReveal() {
        guard let puzzle = Puzzles.puzzle(for: 1) else {
            return XCTFail("Level 1 missing")
        }
        let taps = ["cell-1-3", "cell-1-1", "cell-1-2", "cell-1-4"]
        var marks: Set<String> = []
        var revealed = puzzle.startingRevealed

        for (index, cell) in taps.enumerated() {
            XCTAssertFalse(
                PuzzleEngine.hasContradiction(puzzle, revealed: revealed, marks: marks.union([cell])),
                "Tutorial tap \(index + 1) would be a blown assignment"
            )
            marks.insert(cell)
            let forced = PuzzleEngine.forcedReveal(puzzle, revealed: revealed, marks: marks)
            if index < taps.count - 1 {
                XCTAssertNil(forced, "Tutorial tap \(index + 1) revealed too early")
            } else {
                XCTAssertEqual(forced?.cell, "cell-1-0", "Final tutorial tap must reveal the cornerback")
                XCTAssertEqual(forced?.kind, "cb")
            }
        }
        XCTAssertEqual(marks.count, 4, "The tutorial itself placed exactly the player's four X marks")
    }

    // MARK: - Drive state (downs / blown assignments / drive over)

    @MainActor
    func testBlownAssignmentCostsOneDownAndUndoesMark() async throws {
        let game = GameState()
        game.tutorialSeen = true
        game.activeLevelNumber = 1
        game.replayLevel()

        let puzzle = game.activePuzzle
        guard let hiddenDefender = puzzle.solution.keys.first(where: { puzzle.startingRevealed[$0] == nil }) else {
            return XCTFail("Level 1 has no hidden defender")
        }

        game.tapCell(hiddenDefender)
        XCTAssertEqual(game.puzzleSession.downs, 2, "A blown assignment must cost exactly one down")
        XCTAssertTrue(game.puzzleSession.isAwaitingUndo)
        XCTAssertTrue(game.puzzleSession.marks.contains(hiddenDefender))
        XCTAssertEqual(game.puzzleSession.blownCellId, hiddenDefender)
        XCTAssertFalse(game.puzzleSession.isDriveOver)

        try await Task.sleep(for: .seconds(1.2))
        XCTAssertFalse(game.puzzleSession.marks.contains(hiddenDefender), "The invalid X must be undone")
        XCTAssertFalse(game.puzzleSession.isAwaitingUndo)
        XCTAssertEqual(game.puzzleSession.downs, 2)
        XCTAssertFalse(game.puzzleSession.isDriveOver)
    }

    @MainActor
    func testZeroDownsTriggersDriveOverAndRetryResets() async throws {
        let game = GameState()
        game.tutorialSeen = true
        game.activeLevelNumber = 1
        game.replayLevel()

        let puzzle = game.activePuzzle
        let hidden = puzzle.solution.keys.filter { puzzle.startingRevealed[$0] == nil }
        XCTAssertEqual(hidden.count, 4, "Level 1 should have four hidden defenders")

        for cell in hidden.prefix(3) {
            game.tapCell(cell)
            try await Task.sleep(for: .seconds(1.2))
        }
        XCTAssertEqual(game.puzzleSession.downs, 0)
        XCTAssertTrue(game.puzzleSession.isDriveOver, "Losing the third down must end the drive")

        game.replayLevel()
        XCTAssertEqual(game.puzzleSession.downs, 3, "TRY AGAIN restarts with three fresh downs")
        XCTAssertTrue(game.puzzleSession.marks.isEmpty)
        XCTAssertFalse(game.puzzleSession.isDriveOver)
    }

    // MARK: - Fixtures

    /// A 5x5 puzzle with defenders on (0,0), (1,2), (2,4), (3,1), (4,3) and
    /// five contiguous zones (sizes 5), each holding exactly one defender:
    ///
    ///     A A A B B
    ///     A A A B B
    ///     D D C C C
    ///     D D C E C
    ///     D E E E E
    private func makeTestPuzzle() -> PuzzleDefinition {
        let solution: [String: String] = [
            "cell-0-0": "cb",
            "cell-1-2": "s",
            "cell-2-4": "lb",
            "cell-3-1": "lb",
            "cell-4-3": "cb",
        ]
        let zoneRows = ["AAABB", "AAABB", "DDCCC", "DDCEC", "DEEEE"]
        var zoneOf: [String: Int] = [:]
        for (row, line) in zoneRows.enumerated() {
            for (column, character) in line.enumerated() {
                zoneOf[PuzzleEngine.cellId(row: row, column: column)] = Int(character.asciiValue! - 65)
            }
        }
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
            zoneOf: zoneOf,
            startingRevealed: [:],
            hintCost: 25
        )
    }

    /// True when the zone's cells form one 4-connected region.
    private func isContiguous(_ cellIds: [String]) -> Bool {
        guard let start = cellIds.first else { return false }
        var seen: Set<String> = [start]
        var queue = [start]
        let cellSet = Set(cellIds)

        while let cell = queue.popLast() {
            guard let row = PuzzleEngine.row(ofCellId: cell),
                  let column = PuzzleEngine.column(ofCellId: cell) else { continue }
            for (dr, dc) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
                let neighborRow = row + dr
                let neighborColumn = column + dc
                guard neighborRow >= 0, neighborRow < 5, neighborColumn >= 0, neighborColumn < 5 else { continue }
                let neighbor = PuzzleEngine.cellId(row: neighborRow, column: neighborColumn)
                if cellSet.contains(neighbor), !seen.contains(neighbor) {
                    seen.insert(neighbor)
                    queue.append(neighbor)
                }
            }
        }
        return seen.count == cellIds.count
    }
}
