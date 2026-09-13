import SwiftUI

/// The 15 handcrafted Stadium 1 puzzles. The offensive play above the grid
/// carries the theme; the hidden defense is a 5x5 logic grid solved with three
/// universal rules — one defender per row, one per column, defenders never
/// touch. Every puzzle is machine-verified to have exactly one solution
/// (tools/verify_puzzles.py).
nonisolated enum Puzzles {

    /// Zone geometry used to draw routes into the defensive half of the field.
    /// Purely presentational now that the defensive grid lives below the field.
    nonisolated enum Lattice {
        case a
        case c

        var rows: [CGFloat] {
            switch self {
            case .a: [0.15, 0.30, 0.45]
            case .c: [0.13, 0.27, 0.41, 0.55]
            }
        }

        var columns: [CGFloat] {
            switch self {
            case .a: [0.16, 0.38, 0.62, 0.84]
            case .c: [0.13, 0.32, 0.50, 0.68, 0.87]
            }
        }

        var cell: CGSize {
            switch self {
            case .a: CGSize(width: 0.18, height: 0.12)
            case .c: CGSize(width: 0.17, height: 0.105)
            }
        }

        func point(row: Int, col: Int) -> CGPoint {
            CGPoint(x: columns[col], y: rows[row])
        }
    }

    static func puzzle(for levelNumber: Int) -> PuzzleDefinition? {
        all.first { $0.levelNumber == levelNumber }
    }

    // MARK: - All puzzles

    static let all: [PuzzleDefinition] = [
        makePuzzle(
            level: 1,
            down: "3rd & 7", ballOn: "Ball on 38", clock: 12,
            playName: "Trips Right — Mesh",
            formation: tripsRight,
            solution: [
                "C....",
                "...S.",
                ".L...",
                "....L",
                "..C..",
            ],
            startX: [
                ".XXX.",
                ".X..X",
                "X..XX",
                "XXXX.",
                ".X.X.",
            ],
            startRevealed: [(2, 1)],
            routes: [
                routeInto("r1", .vertical, from: 0.93, to: (0, 3), on: .a, crossBy: -0.04),
                routeInto("r2", .crossing, from: 0.83, to: (0, 1), on: .a, crossBy: -0.20),
                routeInto("r3", .crossing, from: 0.09, to: (1, 2), on: .a, crossBy: 0.24),
                routeInto("r4", .checkdown, from: 0.52, atY: 0.78, to: (2, 2), on: .a, crossBy: 0.06)
            ]
        ),
        makePuzzle(
            level: 2,
            down: "2nd & 5", ballOn: "Ball on 26", clock: 15,
            playName: "Twins Left — Slant Flat",
            formation: twinsLeft,
            solution: [
                "..C..",
                "....S",
                "L....",
                "...L.",
                ".C...",
            ],
            startX: [
                "XX.XX",
                "XX...",
                ".XXX.",
                "X....",
                "X..XX",
            ],
            startRevealed: [(2, 0)],
            routes: [
                routeInto("r1", .crossing, from: 0.90, to: (0, 1), on: .a, crossBy: -0.28),
                routeInto("r2", .vertical, from: 0.72, to: (0, 3), on: .a, crossBy: 0.10),
                routeInto("r3", .crossing, from: 0.19, to: (1, 1), on: .a, crossBy: 0.14),
                routeInto("r4", .vertical, from: 0.09, to: (1, 0), on: .a, crossBy: 0.05),
                routeInto("r5", .checkdown, from: 0.50, atY: 0.78, to: (2, 2), on: .a, crossBy: 0.10)
            ]
        ),
        makePuzzle(
            level: 3,
            down: "3rd & 4", ballOn: "Ball on 45", clock: 10,
            playName: "Spread — Four Verticals",
            formation: spreadEmpty,
            solution: [
                ".C...",
                "...S.",
                "L....",
                "..L..",
                "....C",
            ],
            startX: [
                "X.XXX",
                "X.X.X",
                "..XX.",
                "....X",
                "..XX.",
            ],
            routes: [
                routeInto("r1", .vertical, from: 0.95, to: (0, 0), on: .a, crossBy: -0.06),
                routeInto("r2", .crossing, from: 0.22, to: (0, 2), on: .a, crossBy: 0.22),
                routeInto("r3", .crossing, from: 0.70, to: (1, 1), on: .a, crossBy: -0.14),
                routeInto("r4", .checkdown, from: 0.44, atY: 0.76, to: (2, 1), on: .a, crossBy: -0.08)
            ]
        ),
        makePuzzle(
            level: 4,
            down: "1st & 10", ballOn: "Ball on 20", clock: 20,
            playName: "Tight Y — Deep Cross",
            formation: tightY,
            solution: [
                "..S..",
                "C....",
                "....L",
                ".L...",
                "...C.",
            ],
            startX: [
                "X..XX",
                "....X",
                "XXXX.",
                "X.X..",
                "....X",
            ],
            routes: [
                routeInto("r1", .crossing, from: 0.84, to: (0, 1), on: .a, crossBy: -0.26),
                routeInto("r2", .vertical, from: 0.94, to: (0, 2), on: .a, crossBy: -0.06),
                routeInto("r3", .crossing, from: 0.28, to: (1, 1), on: .a, crossBy: 0.08),
                routeInto("r4", .checkdown, from: 0.50, atY: 0.78, to: (2, 2), on: .a, crossBy: 0.08)
            ]
        ),
        makePuzzle(
            level: 5,
            down: "2nd & 8", ballOn: "Ball on 32", clock: 14,
            playName: "Pro Set — PA Deep Out",
            formation: proSet,
            solution: [
                "....S",
                "..C..",
                "L....",
                "...L.",
                ".C...",
            ],
            startX: [
                ".XXX.",
                "X..XX",
                ".XX.X",
                ".X...",
                "..X..",
            ],
            routes: [
                routeInto("r1", .crossing, from: 0.09, to: (0, 1), on: .a, crossBy: 0.20),
                routeInto("r2", .crossing, from: 0.70, to: (1, 1), on: .a, crossBy: -0.16),
                routeInto("r3", .checkdown, from: 0.52, atY: 0.78, to: (2, 1), on: .a, crossBy: -0.08),
                routeInto("r4", .checkdown, from: 0.44, atY: 0.76, to: (2, 3), on: .a, crossBy: 0.16)
            ]
        ),
        makePuzzle(
            level: 6,
            down: "3rd & 6", ballOn: "Ball on 41", clock: 11,
            playName: "Bunch Right — Levels",
            formation: bunchRight,
            solution: [
                "...C.",
                ".S...",
                "....L",
                "..L..",
                "C....",
            ],
            startX: [
                "X.X..",
                "X..X.",
                "XX.X.",
                "XX..X",
                ".....",
            ],
            routes: [
                routeInto("r1", .crossing, from: 0.86, to: (0, 2), on: .a, crossBy: -0.14),
                routeInto("r2", .vertical, from: 0.68, to: (1, 2), on: .a, crossBy: -0.02),
                routeInto("r3", .checkdown, from: 0.50, atY: 0.78, to: (2, 1), on: .a, crossBy: -0.08),
                routeInto("r4", .checkdown, from: 0.52, atY: 0.76, to: (2, 3), on: .a, crossBy: 0.14)
            ]
        ),
        makePuzzle(
            level: 7,
            down: "2nd & 3", ballOn: "Ball on 18", clock: 16,
            playName: "Twins Right — Quick Game",
            formation: twinsRight,
            solution: [
                "...S.",
                "C....",
                "..L..",
                "....L",
                ".C...",
            ],
            startX: [
                "..X..",
                "...X.",
                "XX..X",
                "X..X.",
                "X..X.",
            ],
            routes: [
                routeInto("r1", .crossing, from: 0.09, to: (0, 0), on: .a, crossBy: 0.04),
                routeInto("r2", .vertical, from: 0.10, to: (1, 0), on: .a, crossBy: 0.03),
                routeInto("r3", .crossing, from: 0.70, to: (2, 0), on: .a, crossBy: -0.22),
                routeInto("r4", .checkdown, from: 0.50, atY: 0.76, to: (2, 2), on: .a, crossBy: 0.08)
            ]
        ),
        makePuzzle(
            level: 8,
            down: "3rd & 9", ballOn: "Ball on 35", clock: 9,
            playName: "Empty Left — Scramble Drill",
            formation: emptySpread,
            solution: [
                ".C...",
                "...S.",
                "L....",
                "....L",
                "..C..",
            ],
            startX: [
                "X.X.X",
                ".....",
                ".XX.X",
                "..X..",
                ".X..X",
            ],
            routes: [
                routeInto("r1", .vertical, from: 0.09, to: (0, 1), on: .a, crossBy: 0.12),
                routeInto("r2", .vertical, from: 0.95, to: (0, 3), on: .a, crossBy: -0.06),
                routeInto("r3", .crossing, from: 0.17, to: (1, 0), on: .a, crossBy: -0.05),
                routeInto("r4", .crossing, from: 0.80, to: (1, 2), on: .a, crossBy: -0.10),
                routeInto("r5", .checkdown, from: 0.44, atY: 0.76, to: (2, 1), on: .a, crossBy: -0.08),
                routeInto("r6", .checkdown, from: 0.52, atY: 0.78, to: (2, 2), on: .a, crossBy: 0.06)
            ]
        ),
        makePuzzle(
            level: 9,
            down: "2nd & 6", ballOn: "Ball on 44", clock: 13,
            playName: "Spread Empty — Mesh Point",
            formation: spreadFive,
            solution: [
                "..S..",
                "C....",
                "...L.",
                ".L...",
                "....C",
            ],
            startX: [
                ".X...",
                ".XX.X",
                "....X",
                "...X.",
                ".XX..",
            ],
            routes: [
                routeInto("r1", .crossing, from: 0.90, to: (0, 3), on: .c, crossBy: -0.20),
                routeInto("r2", .crossing, from: 0.68, to: (1, 3), on: .c, crossBy: -0.08),
                routeInto("r3", .checkdown, from: 0.16, atY: 0.76, to: (2, 1), on: .c, crossBy: 0.08),
                routeInto("r4", .checkdown, from: 0.44, atY: 0.78, to: (2, 2), on: .c, crossBy: 0.04)
            ]
        ),
        makePuzzle(
            level: 10,
            down: "3rd & 5", ballOn: "Ball on 29", clock: 12,
            playName: "Tight Y — Option Route",
            formation: tightSlot,
            solution: [
                "...C.",
                ".S...",
                "....L",
                "..L..",
                "C....",
            ],
            startX: [
                "X...X",
                "X....",
                "X..X.",
                "XX.X.",
                ".....",
            ],
            routes: [
                routeInto("r1", .crossing, from: 0.32, to: (0, 1), on: .c, crossBy: 0.08),
                routeInto("r2", .vertical, from: 0.50, to: (1, 1), on: .c, crossBy: 0.02),
                routeInto("r3", .checkdown, from: 0.82, atY: 0.76, to: (2, 0), on: .c, crossBy: -0.24),
                routeInto("r4", .checkdown, from: 0.50, atY: 0.78, to: (2, 2), on: .c, crossBy: 0.08)
            ]
        ),
        makePuzzle(
            level: 11,
            down: "2nd & 7", ballOn: "Ball on 37", clock: 15,
            playName: "Twins — Dagger",
            formation: twinsRight,
            solution: [
                "..S..",
                "C....",
                "...L.",
                ".L...",
                "....C",
            ],
            startX: [
                ".X...",
                ".....",
                "X...X",
                "...X.",
                "XXX..",
            ],
            routes: [
                routeInto("r1", .crossing, from: 0.09, to: (0, 0), on: .c, crossBy: 0.04),
                routeInto("r2", .vertical, from: 0.10, to: (1, 0), on: .c, crossBy: 0.02),
                routeInto("r3", .checkdown, from: 0.44, atY: 0.76, to: (2, 0), on: .c, crossBy: -0.14),
                routeInto("r4", .checkdown, from: 0.52, atY: 0.78, to: (2, 2), on: .c, crossBy: 0.06)
            ]
        ),
        makePuzzle(
            level: 12,
            down: "1st & 10", ballOn: "Ball on 25", clock: 20,
            playName: "Trips Left — Flood",
            formation: tripsLeft,
            solution: [
                ".S...",
                "...C.",
                "L....",
                "....L",
                "..C..",
            ],
            startX: [
                "....X",
                "X...X",
                ".X..X",
                ".XX..",
                ".....",
            ],
            routes: [
                routeInto("r1", .crossing, from: 0.18, to: (0, 1), on: .c, crossBy: 0.08),
                routeInto("r2", .crossing, from: 0.90, to: (1, 1), on: .c, crossBy: -0.24),
                routeInto("r3", .checkdown, from: 0.16, atY: 0.76, to: (2, 0), on: .c, crossBy: -0.04),
                routeInto("r4", .checkdown, from: 0.50, atY: 0.78, to: (2, 2), on: .c, crossBy: 0.08)
            ]
        ),
        makePuzzle(
            level: 13,
            down: "3rd & 8", ballOn: "Ball on 33", clock: 8,
            playName: "Spread — Double Crossers",
            formation: spreadFour,
            solution: [
                "..C..",
                "S....",
                "...L.",
                ".L...",
                "....C",
            ],
            startX: [
                ".....",
                "....X",
                "X.X.X",
                ".....",
                "..XX.",
            ],
            routes: [
                routeInto("r1", .crossing, from: 0.20, to: (0, 1), on: .c, crossBy: 0.08),
                routeInto("r2", .crossing, from: 0.90, to: (1, 1), on: .c, crossBy: -0.24),
                routeInto("r3", .checkdown, from: 0.44, atY: 0.76, to: (2, 0), on: .c, crossBy: -0.16),
                routeInto("r4", .checkdown, from: 0.52, atY: 0.78, to: (2, 2), on: .c, crossBy: 0.06)
            ]
        ),
        makePuzzle(
            level: 14,
            down: "2nd & 10", ballOn: "Ball on 40", clock: 17,
            playName: "Bunch Left — Smash",
            formation: bunchLeft,
            solution: [
                "..S..",
                "....C",
                ".L...",
                "...L.",
                "C....",
            ],
            startX: [
                "...X.",
                ".....",
                "X.X.X",
                ".....",
                "..X.X",
            ],
            routes: [
                routeInto("r1", .crossing, from: 0.16, to: (0, 1), on: .c, crossBy: 0.06),
                routeInto("r2", .vertical, from: 0.08, to: (1, 0), on: .c, crossBy: 0.02),
                routeInto("r3", .checkdown, from: 0.24, atY: 0.76, to: (2, 1), on: .c, crossBy: 0.04),
                routeInto("r4", .checkdown, from: 0.50, atY: 0.78, to: (2, 3), on: .c, crossBy: 0.06)
            ]
        ),
        makePuzzle(
            level: 15,
            down: "4th & 2", ballOn: "Ball on 15", clock: 25,
            playName: "Championship — All Out",
            formation: championship,
            solution: [
                "....S",
                ".C...",
                "...L.",
                "L....",
                "..C..",
            ],
            startX: [
                ".....",
                "X....",
                "XX..X",
                ".....",
                "...X.",
            ],
            routes: [
                routeInto("r1", .crossing, from: 0.15, to: (0, 1), on: .c, crossBy: 0.06),
                routeInto("r2", .crossing, from: 0.72, to: (1, 1), on: .c, crossBy: -0.14),
                routeInto("r3", .checkdown, from: 0.32, atY: 0.76, to: (2, 1), on: .c, crossBy: -0.06),
                routeInto("r4", .checkdown, from: 0.50, atY: 0.78, to: (2, 2), on: .c, crossBy: 0.06)
            ]
        )
    ]

    // MARK: - Puzzle builder

    // swiftlint:disable:next function_parameter_count
    private static func makePuzzle(
        level: Int,
        down: String,
        ballOn: String,
        clock: Int,
        playName: String,
        formation: [OffensiveMarker],
        solution: [String],
        startX: [String],
        startRevealed: [(Int, Int)] = [],
        routes: [OffensiveRoute]
    ) -> PuzzleDefinition {
        func kindID(_ character: Character) -> String? {
            switch character {
            case "C": "cb"
            case "L": "lb"
            case "S": "s"
            default: nil
            }
        }

        var solutionCells: [String: String] = [:]
        for (row, line) in solution.enumerated() {
            for (column, character) in line.enumerated() {
                if let kind = kindID(character) {
                    solutionCells[PuzzleEngine.cellId(row: row, column: column)] = kind
                }
            }
        }

        var xCells: Set<String> = []
        for (row, line) in startX.enumerated() {
            for (column, character) in line.enumerated() where character == "X" {
                xCells.insert(PuzzleEngine.cellId(row: row, column: column))
            }
        }

        var revealed: [String: String] = [:]
        for (row, column) in startRevealed {
            let id = PuzzleEngine.cellId(row: row, column: column)
            revealed[id] = solutionCells[id]
        }

        return PuzzleDefinition(
            levelNumber: level,
            play: OffensivePlay(
                situation: PlaySituation(
                    levelNumber: level,
                    down: down,
                    ballOn: ballOn,
                    playClock: clock,
                    playName: playName
                ),
                markers: formation,
                routes: routes,
                lineOfScrimmage: 0.62
            ),
            gridSize: solution.count,
            solution: solutionCells,
            startingX: xCells,
            startingRevealed: revealed,
            hintCost: 25
        )
    }

    // MARK: - Route helper

    /// A route that climbs from the offensive side into the defensive half, so
    /// the play diagram reads like real route traffic. Thematic only.
    private static func routeInto(
        _ id: String,
        _ kind: RouteKind,
        from x: CGFloat,
        atY y: CGFloat = 0.57,
        to zone: (Int, Int),
        on lattice: Lattice,
        crossBy: CGFloat
    ) -> OffensiveRoute {
        let target = lattice.point(row: zone.0, col: zone.1)
        var points = [CGPoint(x: x, y: y)]
        if crossBy != 0 {
            points.append(CGPoint(x: x + crossBy, y: (y + target.y) / 2 + 0.05))
        }
        points.append(CGPoint(x: target.x, y: target.y + 0.035))
        return OffensiveRoute(id: id, kind: kind, points: points)
    }

    // MARK: - Formations

    private static func baseLine() -> [OffensiveMarker] {
        [
            OffensiveMarker(id: "lt", label: "LT", point: CGPoint(x: 0.28, y: 0.62), isEligible: false),
            OffensiveMarker(id: "lg", label: "LG", point: CGPoint(x: 0.36, y: 0.62), isEligible: false),
            OffensiveMarker(id: "c", label: "C", point: CGPoint(x: 0.44, y: 0.62), isEligible: false),
            OffensiveMarker(id: "rg", label: "RG", point: CGPoint(x: 0.52, y: 0.62), isEligible: false),
            OffensiveMarker(id: "rt", label: "RT", point: CGPoint(x: 0.60, y: 0.62), isEligible: false),
            OffensiveMarker(id: "qb", label: "QB", point: CGPoint(x: 0.44, y: 0.76), isEligible: true)
        ]
    }

    private static func marker(_ id: String, _ label: String, _ x: CGFloat, eligible: Bool) -> OffensiveMarker {
        OffensiveMarker(id: id, label: label, point: CGPoint(x: x, y: 0.62), isEligible: eligible)
    }

    private static func runningBack() -> OffensiveMarker {
        OffensiveMarker(id: "rb", label: "RB", point: CGPoint(x: 0.50, y: 0.86), isEligible: true)
    }

    private static let tripsRight: [OffensiveMarker] =
        baseLine() + [runningBack()] + [
            marker("wr-x", "WR", 0.09, eligible: true),
            marker("te", "TE", 0.72, eligible: true),
            marker("wr-slot", "WR", 0.83, eligible: true),
            marker("wr-z", "WR", 0.93, eligible: true)
        ]

    private static let twinsLeft: [OffensiveMarker] =
        baseLine() + [runningBack()] + [
            marker("wr-x", "WR", 0.09, eligible: true),
            marker("wr-h", "WR", 0.19, eligible: true),
            marker("te", "TE", 0.72, eligible: true),
            marker("wr-z", "WR", 0.90, eligible: true)
        ]

    private static let spreadEmpty: [OffensiveMarker] =
        baseLine() + [
            marker("wr-1", "WR", 0.07, eligible: true),
            marker("wr-2", "WR", 0.22, eligible: true),
            marker("wr-3", "WR", 0.70, eligible: true),
            marker("wr-4", "WR", 0.84, eligible: true),
            marker("wr-5", "WR", 0.95, eligible: true)
        ]

    private static let tightY: [OffensiveMarker] =
        baseLine() + [runningBack()] + [
            marker("te", "TE", 0.28, eligible: true),
            marker("wr-z", "WR", 0.84, eligible: true),
            marker("wr-x", "WR", 0.94, eligible: true)
        ]

    private static let proSet: [OffensiveMarker] =
        baseLine() + [runningBack()] + [
            marker("wr-x", "WR", 0.09, eligible: true),
            marker("te", "TE", 0.70, eligible: true),
            marker("wr-z", "WR", 0.91, eligible: true)
        ]

    private static let bunchRight: [OffensiveMarker] =
        baseLine() + [runningBack()] + [
            marker("wr-x", "WR", 0.07, eligible: true),
            marker("wr-1", "WR", 0.68, eligible: true),
            marker("wr-2", "WR", 0.76, eligible: true),
            marker("wr-3", "WR", 0.86, eligible: true)
        ]

    private static let twinsRight: [OffensiveMarker] =
        baseLine() + [runningBack()] + [
            marker("wr-x", "WR", 0.10, eligible: true),
            marker("wr-1", "WR", 0.70, eligible: true),
            marker("wr-2", "WR", 0.80, eligible: true)
        ]

    private static let emptySpread: [OffensiveMarker] =
        baseLine() + [
            marker("wr-1", "WR", 0.07, eligible: true),
            marker("wr-2", "WR", 0.17, eligible: true),
            marker("wr-3", "WR", 0.80, eligible: true),
            marker("wr-4", "WR", 0.93, eligible: true)
        ]

    private static let spreadFive: [OffensiveMarker] =
        baseLine() + [
            marker("wr-1", "WR", 0.05, eligible: true),
            marker("wr-2", "WR", 0.16, eligible: true),
            marker("wr-3", "WR", 0.76, eligible: true),
            marker("wr-4", "WR", 0.90, eligible: true),
            marker("wr-5", "WR", 0.97, eligible: true)
        ]

    private static let tightSlot: [OffensiveMarker] =
        baseLine() + [runningBack()] + [
            marker("te", "TE", 0.26, eligible: true),
            marker("wr-slot", "WR", 0.50, eligible: true),
            marker("wr-z", "WR", 0.82, eligible: true),
            marker("wr-x", "WR", 0.94, eligible: true)
        ]

    private static let tripsLeft: [OffensiveMarker] =
        baseLine() + [runningBack()] + [
            marker("wr-1", "WR", 0.08, eligible: true),
            marker("wr-2", "WR", 0.18, eligible: true),
            marker("wr-3", "WR", 0.28, eligible: true),
            marker("wr-z", "WR", 0.90, eligible: true)
        ]

    private static let spreadFour: [OffensiveMarker] =
        baseLine() + [runningBack()] + [
            marker("wr-1", "WR", 0.06, eligible: true),
            marker("wr-2", "WR", 0.20, eligible: true),
            marker("wr-3", "WR", 0.74, eligible: true),
            marker("wr-4", "WR", 0.90, eligible: true)
        ]

    private static let bunchLeft: [OffensiveMarker] =
        baseLine() + [runningBack()] + [
            marker("wr-1", "WR", 0.08, eligible: true),
            marker("wr-2", "WR", 0.16, eligible: true),
            marker("wr-3", "WR", 0.24, eligible: true),
            marker("wr-x", "WR", 0.92, eligible: true)
        ]

    private static let championship: [OffensiveMarker] =
        baseLine() + [runningBack()] + [
            marker("wr-1", "WR", 0.05, eligible: true),
            marker("wr-2", "WR", 0.15, eligible: true),
            marker("wr-3", "WR", 0.72, eligible: true),
            marker("wr-4", "WR", 0.84, eligible: true),
            marker("wr-5", "WR", 0.95, eligible: true)
        ]
}
