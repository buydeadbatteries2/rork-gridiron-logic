import SwiftUI

/// PLAY tab: the live puzzle board. Mark impossible squares with X, let the
/// Smart Reveal cascade uncover the hidden defense, and celebrate the stop.
struct PlayScreen: View {
    @Environment(GameState.self) private var game

    @State private var showsSettings: Bool = false
    @State private var showsHintAlert: Bool = false
    @State private var showsRules: Bool = false

    private var play: OffensivePlay { game.activePlay }
    private var puzzle: PuzzleDefinition { game.activePuzzle }
    private var session: PuzzleSession { game.puzzleSession }

    var body: some View {
        ZStack(alignment: .top) {
            StadiumSkyBackdrop()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    situationPanel
                    playNameCard
                    fieldCard
                    gridCard
                    statusCard
                }
                .padding(.horizontal, 14)
                .padding(.top, 68)
                .padding(.bottom, 130)
            }

            TopStatusBar(progress: game.progress) { showsSettings = true }
                .background {
                    LinearGradient(
                        colors: [Palette.canvasDeep.opacity(0.98), Palette.canvasDeep.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(edges: .top)
                }

            toastBanner

            if session.isComplete {
                WinOverlay(
                    stars: session.earnedStars,
                    reward: game.activeLevelReward,
                    levelTitle: "Level \(play.situation.levelNumber) — \(play.situation.playName)",
                    celebration: game.equippedCelebration?.preview,
                    canPlayNext: game.canPlayNextLevel,
                    onNext: { game.loadNextLevel() },
                    onReplay: { game.replayLevel() }
                )
                .transition(.scale(scale: 0.85).combined(with: .opacity))
                .zIndex(10)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: session.isComplete)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: session.toastToken)
        .sheet(isPresented: $showsSettings) { SettingsSheet() }
        .sheet(isPresented: $showsRules) { RulesSheet() }
        .alert("Not Enough Game Balls", isPresented: $showsHintAlert) {
            Button("Got It", role: .cancel) {}
        } message: {
            Text("Hints cost \(puzzle.hintCost) Game Balls. Earn more by clearing levels or visiting the Shop.")
        }
        .overlay {
            if game.showTutorial {
                TutorialOverlay(onFinish: { game.dismissTutorial() })
                    .zIndex(20)
            }
        }
        .task(id: session.toastToken) {
            guard session.toastText != nil else { return }
            try? await Task.sleep(for: .seconds(1.5))
            game.clearToast()
        }
        .sensoryFeedback(.success, trigger: session.revealed.count)
        .sensoryFeedback(.error, trigger: session.mistakeToken)
    }

    // MARK: - Scoreboard

    private var situationPanel: some View {
        HStack(spacing: 0) {
            situationCell(title: nil, value: "LEVEL \(play.situation.levelNumber)")
            divider
            situationCell(title: nil, value: play.situation.down.uppercased())
            divider
            situationCell(title: nil, value: play.situation.ballOn.uppercased())
            divider
            VStack(spacing: 2) {
                Text("PLAY CLOCK")
                    .broadcastLabel(9)
                    .foregroundStyle(Palette.muted)
                Text(":\(play.situation.playClock)")
                    .scoreboardNumber(18)
                    .foregroundStyle(Palette.accentBright)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Palette.surface.opacity(0.95))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Palette.stroke, lineWidth: 1)
                }
        }
    }

    private func situationCell(title: String?, value: String) -> some View {
        VStack(spacing: 2) {
            if let title {
                Text(title)
                    .broadcastLabel(9)
                    .foregroundStyle(Palette.muted)
            }
            Text(value)
                .broadcastHeadline(15, tracking: 1)
                .foregroundStyle(Palette.chalk)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
    }

    private var divider: some View {
        Rectangle()
            .fill(Palette.stroke)
            .frame(width: 1, height: 30)
    }

    private var playNameCard: some View {
        VStack(spacing: 3) {
            Text("OFFENSIVE PLAY")
                .broadcastLabel(10)
                .foregroundStyle(Palette.muted)
            Text(play.situation.playName.uppercased())
                .broadcastHeadline(24, tracking: 1.5)
                .foregroundStyle(Palette.chalk)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Palette.surface.opacity(0.95))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Palette.stroke, lineWidth: 1)
                }
        }
    }

    // MARK: - Field + Grid

    private var fieldCard: some View {
        FootballField(play: play)
            .frame(height: 230)
            .clipShape(.rect(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Palette.stroke, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.5), radius: 14, y: 6)
    }

    private var gridCard: some View {
        VStack(spacing: 10) {
            HStack {
                Text("HIDDEN DEFENSE")
                    .broadcastLabel(10)
                    .foregroundStyle(Palette.muted)
                Spacer()
                Text("\(session.revealed.count) OF \(puzzle.solution.count) FOUND")
                    .scoreboardNumber(12)
                    .foregroundStyle(Palette.gold)
            }

            DefensiveGrid(
                puzzle: puzzle,
                marks: session.marks,
                autoEliminated: session.autoEliminated,
                mistakes: session.mistakes,
                revealed: session.revealed,
                hintFlashCellId: session.hintFlashCellId,
                mistakeCellId: session.mistakeCellId,
                mistakeToken: session.mistakeToken,
                onTap: { game.tapCell($0) },
                onLongPress: { game.removeMark($0) }
            )
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Palette.surface.opacity(0.95))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Palette.stroke, lineWidth: 1)
                }
        }
        .shadow(color: .black.opacity(0.4), radius: 12, y: 5)
    }

    // MARK: - Status card

    private var statusCard: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Palette.blue)
                .frame(width: 36, height: 36)
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Palette.blue.opacity(0.16))
                }

            VStack(alignment: .leading, spacing: 3) {
                Text("Mark squares that can't hide a defender.")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.chalk)
                Text("Tap an X again to test it. Long-press to erase.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Palette.muted)
            }

            Spacer(minLength: 0)

            rulesButton
            hintButton
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Palette.surface.opacity(0.95))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Palette.stroke, lineWidth: 1)
                }
        }
    }

    private var rulesButton: some View {
        Button {
            showsRules = true
        } label: {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Palette.muted)
                .frame(width: 40, height: 48)
        }
        .buttonStyle(NodePressStyle())
        .accessibilityLabel("Puzzle rules")
    }

    private var hintButton: some View {
        Button {
            handleHint()
        } label: {
            VStack(spacing: 2) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Palette.canvasDeep)
                HStack(spacing: 3) {
                    if session.freeHintUsed {
                        Image(systemName: "figure.american.football")
                            .font(.system(size: 9, weight: .black))
                    }
                    Text(session.freeHintUsed ? "\(puzzle.hintCost)" : "FREE")
                        .scoreboardNumber(10)
                }
                .foregroundStyle(Palette.canvasDeep.opacity(0.85))
            }
            .frame(width: 56, height: 48)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Palette.gold)
                    .shadow(color: Palette.gold.opacity(0.35), radius: 8, y: 2)
            }
        }
        .buttonStyle(NodePressStyle())
        .accessibilityLabel(session.freeHintUsed ? "Buy hint for \(puzzle.hintCost) game balls" : "Free hint")
    }

    private func handleHint() {
        switch game.requestHint() {
        case .some(.insufficientBalls):
            showsHintAlert = true
        case .some(.placed), .none:
            break
        }
    }

    // MARK: - Toast

    @ViewBuilder
    private var toastBanner: some View {
        if let toast = session.toastText {
            let tint = session.toastIsMistake ? Palette.accent : Palette.blue
            Text(toast)
                .broadcastHeadline(15, tracking: 1.5)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 11)
                .background {
                    Capsule()
                        .fill(tint.opacity(0.94))
                        .shadow(color: tint.opacity(0.65), radius: 14)
                }
                .padding(.top, 104)
                .id(session.toastToken)
                .transition(.scale(scale: 0.75).combined(with: .opacity))
                .zIndex(5)
        }
    }
}
