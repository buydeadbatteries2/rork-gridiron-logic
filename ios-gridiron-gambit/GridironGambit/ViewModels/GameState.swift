import SwiftUI
import Observation

/// Tabs in the root navigation.
nonisolated enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case road = "Road"
    case play = "Play"
    case locker = "Locker"
    case shop = "Shop"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .road: "point.topleft.down.to.point.bottomright.curvepath.fill"
        case .play: "figure.american.football"
        case .locker: "shield.lefthalf.filled"
        case .shop: "cart.fill"
        }
    }
}

/// Result of tapping the hint button.
nonisolated enum HintOutcome: Sendable, Equatable {
    case shown(isFree: Bool)
    case insufficientBalls
}

/// Single source of truth for game state: progress, the active puzzle,
/// the live puzzle session, and local persistence.
@Observable
final class GameState {
    var progress: PlayerProgress = .starting
    var selectedTab: AppTab = .road
    var stadiums: [Stadium] = MockData.stadiums
    var cosmetics: [CosmeticItem] = MockData.cosmetics

    /// Best star count per cleared level.
    var starRecords: [Int: Int] = [:]

    /// Level chosen from the road and loaded into the Play tab.
    var activeLevelNumber: Int = 1
    var puzzleSession = PuzzleSession()

    /// Guided first-time tutorial on Level 1: highlights one square at a time
    /// and teaches through action. Nil when not guiding.
    var guideCellId: String? = nil
    var guideMessage: String? = nil
    private var guideSteps: [GuideStep] = []
    private var guideIndex = 0
    /// Whether the guided tutorial has been completed or skipped.
    var tutorialSeen: Bool = false

    init() {
        loadSavedProgress()
        resetSession()
    }

    // MARK: - Derived content

    var currentStadium: Stadium {
        stadiums.first { progress.currentLevelNumber >= $0.firstLevel && progress.currentLevelNumber <= $0.lastLevel }
            ?? stadiums[0]
    }

    func stadium(containing levelNumber: Int) -> Stadium {
        stadiums.first { levelNumber >= $0.firstLevel && levelNumber <= $0.lastLevel } ?? stadiums[0]
    }

    func levels(for stadium: Stadium) -> [Level] {
        MockData.levels(for: stadium, progress: progress, starRecords: starRecords)
    }

    /// Road stops for a stadium, ordered from the last level down to the first
    /// so the road reads bottom-up toward the stadium marquee.
    func roadStops(for stadium: Stadium) -> [RoadStop] {
        let levels = MockData.levels(for: stadium, progress: progress, starRecords: starRecords)
        let rewards = MockData.rewardStops(for: stadium)
        var stops: [RoadStop] = []

        for level in levels {
            stops.append(level.isGameDay ? .gameDay(level) : .level(level))
            if let reward = rewards.first(where: { $0.afterLevel == level.levelNumber }) {
                stops.append(.reward(reward))
            }
        }
        return stops.reversed()
    }

    /// Levels remaining before the stadium's Game Day finale.
    func playsToStadium(for stadium: Stadium) -> Int {
        max(0, stadium.lastLevel - progress.currentLevelNumber)
    }

    var activePuzzle: PuzzleDefinition {
        Puzzles.puzzle(for: activeLevelNumber) ?? Puzzles.all[0]
    }

    var activePlay: OffensivePlay {
        activePuzzle.play
    }

    var activeLevel: Level? {
        levels(for: stadium(containing: activeLevelNumber)).first { $0.levelNumber == activeLevelNumber }
    }

    /// Reward the active level will pay on a win.
    var activeLevelReward: LevelReward {
        let stadium = stadium(containing: activeLevelNumber)
        let index = activeLevelNumber - stadium.firstLevel
        let isGameDay = activeLevelNumber == stadium.lastLevel
        return LevelReward(
            gameBalls: isGameDay ? 250 : 25 + index * 5,
            xp: isGameDay ? 200 : 40
        )
    }

    /// True when the next level exists and is already unlocked (a replay win).
    var canPlayNextLevel: Bool {
        guard Puzzles.puzzle(for: activeLevelNumber + 1) != nil else { return false }
        return activeLevelNumber + 1 <= progress.currentLevelNumber
    }

    func cosmetics(in category: LockerCategory) -> [CosmeticItem] {
        cosmetics.filter { $0.category == category }
    }

    var equippedCelebration: CosmeticItem? {
        cosmetics.first { $0.category == .celebration && $0.isEquipped }
    }

    // MARK: - Navigation

    /// Opens a level in the Play tab.
    func openLevel(_ level: Level) {
        guard level.isUnlocked else { return }
        activeLevelNumber = level.levelNumber
        resetSession()
        selectedTab = .play
    }

    /// Loads the next level directly from the win celebration.
    func loadNextLevel() {
        guard canPlayNextLevel else {
            selectedTab = .road
            return
        }
        activeLevelNumber += 1
        resetSession()
    }

    /// Replays the current level from a clean board.
    func replayLevel() {
        resetSession()
    }

    private func resetSession() {
        let puzzle = activePuzzle
        var session = PuzzleSession()
        session.revealed = puzzle.startingRevealed
        puzzleSession = session
        setupGuide()
    }

    // MARK: - Puzzle interaction

    /// The one primary interaction: tap an empty square to place an X, tap the
    /// X to remove it. After every toggle the engine evaluates the board ONCE —
    /// at most a single reveal, no automatic X marks, no chain reactions.
    func tapCell(_ cellId: String) {
        guard !puzzleSession.isComplete else { return }
        let puzzle = activePuzzle
        guard puzzleSession.revealed[cellId] == nil,
              !puzzle.startingX.contains(cellId) else { return }

        // Guided tutorial: only the highlighted square responds.
        if guideCellId != nil, cellId != guideCellId { return }

        if puzzleSession.marks.contains(cellId) {
            puzzleSession.marks.remove(cellId)
        } else {
            puzzleSession.marks.insert(cellId)
        }

        advanceGuide(for: cellId)
        evaluateBoard()
    }

    /// One evaluation per player action: a single reveal if the player's marks
    /// legitimately closed a line onto its solution, otherwise a subtle
    /// contradiction check. Nothing else happens — the board is otherwise
    /// completely static without input.
    private func evaluateBoard() {
        let puzzle = activePuzzle

        if let forced = PuzzleEngine.forcedReveal(
            puzzle,
            revealed: puzzleSession.revealed,
            marks: puzzleSession.marks
        ) {
            revealDefender(cell: forced.cell, kind: forced.kind)
            return
        }

        let contradictory = PuzzleEngine.hasContradiction(
            puzzle,
            revealed: puzzleSession.revealed,
            marks: puzzleSession.marks
        )
        if contradictory, !puzzleSession.hasContradiction {
            puzzleSession.mistakeCount += 1
            showToast("CHECK YOUR BLOCKS", isMistake: true)
        }
        puzzleSession.hasContradiction = contradictory
    }

    private func revealDefender(cell: String, kind: String) {
        puzzleSession.revealed[cell] = kind
        showToast("DEFENDER REVEALED!", isMistake: false)
        checkCompletion()
    }

    private func checkCompletion() {
        guard puzzleSession.revealed.count >= activePuzzle.solution.count,
              !puzzleSession.isComplete else { return }
        // Let the final reveal land before the celebration takes over.
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.1))
            guard let self,
                  !self.puzzleSession.isComplete,
                  self.puzzleSession.revealed.count >= self.activePuzzle.solution.count else { return }
            self.completeActiveLevel()
        }
    }

    // MARK: - Hints

    /// First hint each level is free; later ones cost Game Balls. A hint only
    /// HIGHLIGHTS one square that can logically be X'd — the player places the
    /// mark themselves. Never places marks or reveals defenders.
    func requestHint() -> HintOutcome? {
        guard !puzzleSession.isComplete, guideCellId == nil else { return nil }
        let puzzle = activePuzzle

        guard let cell = PuzzleEngine.hintXCell(
            puzzle,
            revealed: puzzleSession.revealed,
            marks: puzzleSession.marks
        ) else { return nil }

        var isFree = false
        if !puzzleSession.freeHintUsed {
            puzzleSession.freeHintUsed = true
            isFree = true
        } else {
            let cost = puzzle.hintCost
            guard progress.gameBalls >= cost else { return .insufficientBalls }
            progress.gameBalls -= cost
            puzzleSession.paidHints += 1
        }

        puzzleSession.hintFlashCellId = cell
        flashHint()
        save()
        return .shown(isFree: isFree)
    }

    private func flashHint() {
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.6))
            self?.puzzleSession.hintFlashCellId = nil
        }
    }

    // MARK: - Toasts

    private func showToast(_ text: String, isMistake: Bool) {
        puzzleSession.toastText = text
        puzzleSession.toastIsMistake = isMistake
        puzzleSession.toastToken += 1
    }

    /// Called by the UI once a toast has been on screen long enough.
    func clearToast() {
        puzzleSession.toastText = nil
    }

    // MARK: - Guided tutorial

    private struct GuideStep {
        let cellId: String
        let message: String
    }

    private func setupGuide() {
        guideSteps = []
        guideIndex = 0
        guideCellId = nil
        guideMessage = nil
        guard activeLevelNumber == 1, !tutorialSeen else { return }

        // Guided taps on the real Level 1 board. The first two place harmless
        // X marks; the final one closes row 1 onto its safety and triggers the
        // reveal through the normal engine path.
        guideSteps = [
            GuideStep(cellId: PuzzleEngine.cellId(row: 4, column: 4), message: "TAP THIS SQUARE TO BLOCK IT."),
            GuideStep(cellId: PuzzleEngine.cellId(row: 1, column: 0), message: "GOOD. THIS SPACE CAN'T HOLD A DEFENDER EITHER."),
            GuideStep(cellId: PuzzleEngine.cellId(row: 1, column: 4), message: "ONE MORE. TAP THIS SQUARE TO BLOCK IT."),
        ]
        guideCellId = guideSteps[0].cellId
        guideMessage = guideSteps[0].message
    }

    private func advanceGuide(for cellId: String) {
        guard guideCellId != nil,
              guideIndex < guideSteps.count,
              guideSteps[guideIndex].cellId == cellId else { return }

        guideIndex += 1
        if guideIndex < guideSteps.count {
            guideCellId = guideSteps[guideIndex].cellId
            guideMessage = guideSteps[guideIndex].message
        } else {
            finishGuide()
        }
    }

    private func finishGuide() {
        guideCellId = nil
        guideMessage = "NICE! BLOCK EVERY IMPOSSIBLE SPACE AND THE DEFENDER IS REVEALED."
        tutorialSeen = true
        save()

        let level = activeLevelNumber
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(3.2))
            guard let self, self.activeLevelNumber == level else { return }
            self.guideMessage = "NOW USE THE SAME RULES TO FIND THE NEXT DEFENDER."
            try? await Task.sleep(for: .seconds(3.2))
            guard self.activeLevelNumber == level else { return }
            self.guideMessage = nil
        }
    }

    /// Skips the guided tutorial for good.
    func skipGuide() {
        guideSteps = []
        guideIndex = 0
        guideCellId = nil
        guideMessage = nil
        tutorialSeen = true
        save()
    }

    // MARK: - Completion

    /// Pays out the level: stars, Game Balls, XP, level-up, unlock, persistence.
    private func completeActiveLevel() {
        let levelNumber = activeLevelNumber
        let reward = activeLevelReward
        let stars = PuzzleEngine.stars(mistakes: puzzleSession.mistakeCount)

        progress.gameBalls += reward.gameBalls
        progress.xp += reward.xp
        while progress.xp >= progress.xpForNextLevel {
            progress.xp -= progress.xpForNextLevel
            progress.playerLevel += 1
        }
        progress.rank = Self.rank(for: progress.playerLevel)

        starRecords[levelNumber] = max(starRecords[levelNumber] ?? 0, stars.rawValue)
        progress.stars = starRecords.values.reduce(0, +)
        if levelNumber >= progress.currentLevelNumber {
            progress.currentLevelNumber = levelNumber + 1
        }

        puzzleSession.isComplete = true
        puzzleSession.earnedStars = stars
        save()
    }

    private static func rank(for playerLevel: Int) -> PlayerRank {
        switch playerLevel {
        case ..<3: .rookie
        case ..<5: .assistant
        case ..<7: .positionCoach
        case ..<9: .coordinator
        case ..<12: .headCoach
        default: .legend
        }
    }

    // MARK: - Locker

    /// Equips an owned cosmetic, unequipping others in its category.
    func equip(_ item: CosmeticItem) {
        guard item.isOwned else { return }
        for index in cosmetics.indices where cosmetics[index].category == item.category {
            cosmetics[index].isEquipped = cosmetics[index].id == item.id
        }
        save()
    }

    // MARK: - Persistence

    private func loadSavedProgress() {
        guard let saved = ProgressStore.load() else { return }
        progress.playerLevel = max(1, saved.playerLevel)
        progress.xp = max(0, saved.xp)
        progress.gameBalls = max(0, saved.gameBalls)
        progress.currentLevelNumber = max(1, saved.currentLevelNumber)
        progress.rank = Self.rank(for: progress.playerLevel)
        progress.stars = saved.starsByLevel.values.reduce(0, +)
        starRecords = saved.starsByLevel
        tutorialSeen = saved.tutorialSeen ?? false
        activeLevelNumber = min(progress.currentLevelNumber, MockData.stadiums[0].lastLevel)

        for (categoryRaw, itemID) in saved.equippedCosmetics {
            for index in cosmetics.indices
            where cosmetics[index].category.rawValue == categoryRaw {
                cosmetics[index].isEquipped = cosmetics[index].id == itemID
            }
        }
    }

    private func save() {
        var equipped: [String: String] = [:]
        for item in cosmetics where item.isEquipped {
            equipped[item.category.rawValue] = item.id
        }
        ProgressStore.save(
            SavedProgress(
                currentLevelNumber: progress.currentLevelNumber,
                playerLevel: progress.playerLevel,
                xp: progress.xp,
                gameBalls: progress.gameBalls,
                starsByLevel: starRecords,
                equippedCosmetics: equipped,
                tutorialSeen: tutorialSeen
            )
        )
    }

    /// Wipes local progress and returns to a fresh career.
    func resetProgress() {
        ProgressStore.clear()
        progress = .starting
        starRecords = [:]
        cosmetics = MockData.cosmetics
        activeLevelNumber = 1
        tutorialSeen = false
        resetSession()
        save()
    }
}
