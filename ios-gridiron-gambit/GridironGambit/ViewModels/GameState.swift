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
    case placed(isFree: Bool)
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

    /// First-time, five-screen tutorial over the Level 1 board.
    var showTutorial: Bool = false
    var tutorialSeen: Bool = false

    /// True while the Smart Reveal chain is cascading — input is locked.
    private var isChaining = false
    /// Bumped on every session reset so stale chain tasks abort.
    private var chainGeneration = 0

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
        showTutorial = activeLevelNumber == 1 && !tutorialSeen
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
        chainGeneration += 1
        let puzzle = activePuzzle
        var session = PuzzleSession()
        session.revealed = puzzle.startingRevealed
        session.autoEliminated = PuzzleEngine.impossibleCells(puzzle, revealed: session.revealed)
        puzzleSession = session
        isChaining = false
        runSmartReveals(initialDelay: .seconds(0.9))
    }

    // MARK: - Puzzle interaction

    /// The one primary interaction. First tap marks an X; tapping an existing
    /// player mark tests the square for a hidden defender.
    func tapCell(_ cellId: String) {
        guard !puzzleSession.isComplete, !isChaining else { return }
        let puzzle = activePuzzle
        guard puzzleSession.revealed[cellId] == nil,
              !puzzle.startingX.contains(cellId),
              !puzzleSession.autoEliminated.contains(cellId),
              !puzzleSession.mistakes.contains(cellId) else { return }

        if puzzleSession.marks.contains(cellId) {
            attemptReveal(cellId, puzzle: puzzle)
        } else {
            puzzleSession.marks.insert(cellId)
            runSmartReveals(initialDelay: .seconds(0.4))
        }
    }

    /// Long-press erases a player X mark. Marks are free — no penalties ever.
    func removeMark(_ cellId: String) {
        guard !puzzleSession.isComplete, !isChaining else { return }
        puzzleSession.marks.remove(cellId)
    }

    private func attemptReveal(_ cellId: String, puzzle: PuzzleDefinition) {
        if let kindID = puzzle.solution[cellId] {
            puzzleSession.marks.remove(cellId)
            revealDefender(cellId: cellId, kindID: kindID)
        } else {
            // One mistake, no reset: the square locks as an X and play continues.
            puzzleSession.wrongReveals += 1
            puzzleSession.marks.remove(cellId)
            puzzleSession.mistakes.insert(cellId)
            puzzleSession.mistakeCellId = cellId
            puzzleSession.mistakeToken += 1
            showToast("NOT HERE", isMistake: true)
        }
    }

    private func revealDefender(cellId: String, kindID: String) {
        puzzleSession.revealed[cellId] = kindID
        puzzleSession.autoEliminated = PuzzleEngine.impossibleCells(activePuzzle, revealed: puzzleSession.revealed)
        showToast("DEFENDER REVEALED!", isMistake: false)
        checkCompletion()
        runSmartReveals()
    }

    /// Smart Reveal: whenever a row or column has exactly one unblocked cell
    /// left, its defender reveals automatically — cascading into chains.
    private func runSmartReveals(initialDelay: Duration = .seconds(0.55)) {
        guard !isChaining else { return }
        isChaining = true
        chainGeneration += 1
        let generation = chainGeneration

        Task { [weak self] in
            guard let self else { return }
            if initialDelay > .zero {
                try? await Task.sleep(for: initialDelay)
            }
            while !Task.isCancelled, generation == self.chainGeneration, !self.puzzleSession.isComplete {
                let forced = PuzzleEngine.forcedReveals(
                    self.activePuzzle,
                    revealed: self.puzzleSession.revealed,
                    marks: self.puzzleSession.marks
                )
                guard let cellId = PuzzleEngine.sortedReadingOrder(forced.keys).first,
                      let kindID = forced[cellId] else { break }

                self.puzzleSession.revealed[cellId] = kindID
                self.puzzleSession.autoEliminated = PuzzleEngine.impossibleCells(
                    self.activePuzzle, revealed: self.puzzleSession.revealed
                )
                self.showToast("DEFENDER REVEALED!", isMistake: false)
                self.checkCompletion()
                try? await Task.sleep(for: .seconds(0.55))
            }
            if generation == self.chainGeneration {
                self.isChaining = false
            }
        }
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

    /// First hint each level is free; later ones cost Game Balls.
    /// Prefers placing a correct X; falls back to revealing a hidden defender.
    func requestHint() -> HintOutcome? {
        guard !puzzleSession.isComplete, !isChaining else { return nil }
        let puzzle = activePuzzle
        let marks = puzzleSession.marks.union(puzzleSession.mistakes)

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

        if let xCell = PuzzleEngine.hintXCell(puzzle, revealed: puzzleSession.revealed, marks: marks) {
            puzzleSession.marks.insert(xCell)
            puzzleSession.hintFlashCellId = xCell
            flashHint()
            runSmartReveals(initialDelay: .seconds(0.5))
        } else if let cellId = PuzzleEngine.hintRevealCell(puzzle, revealed: puzzleSession.revealed),
                  let kindID = puzzle.solution[cellId] {
            puzzleSession.marks.remove(cellId)
            puzzleSession.hintFlashCellId = cellId
            flashHint()
            revealDefender(cellId: cellId, kindID: kindID)
        }

        save()
        return .placed(isFree: isFree)
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

    // MARK: - Tutorial

    /// Dismisses the first-time tutorial for good.
    func dismissTutorial() {
        showTutorial = false
        tutorialSeen = true
        save()
    }

    // MARK: - Completion

    /// Pays out the level: stars, Game Balls, XP, level-up, unlock, persistence.
    private func completeActiveLevel() {
        let levelNumber = activeLevelNumber
        let reward = activeLevelReward
        let stars = PuzzleEngine.stars(wrongReveals: puzzleSession.wrongReveals)

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
