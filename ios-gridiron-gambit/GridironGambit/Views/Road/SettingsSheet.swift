import SwiftUI

/// Lightweight local settings surface for Phase 1.
struct SettingsSheet: View {
    @Environment(GameState.self) private var game
    @Environment(\.dismiss) private var dismiss

    @State private var soundEnabled: Bool = true
    @State private var hapticsEnabled: Bool = true
    @State private var hintsEnabled: Bool = true
    @State private var showsResetConfirm: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        HelmetGlyph(shell: Palette.surfaceRaised, facemask: Palette.chalk, stripe: Palette.accent)
                            .frame(width: 54, height: 46)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(game.progress.rank.rawValue)
                                .broadcastHeadline(22, tracking: 1)
                                .foregroundStyle(Palette.chalk)
                            Text("Coach Level \(game.progress.playerLevel)")
                                .broadcastLabel(10)
                                .foregroundStyle(Palette.muted)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 6)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("XP")
                                .broadcastLabel(10)
                                .foregroundStyle(Palette.muted)
                            Spacer()
                            Text("\(game.progress.xp) / \(game.progress.xpForNextLevel)")
                                .scoreboardNumber(12)
                                .foregroundStyle(Palette.chalk)
                        }

                        ProgressView(value: game.progress.xpProgress)
                            .tint(Palette.accent)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Coach")
                }

                Section {
                    Toggle("Sound", isOn: $soundEnabled)
                    Toggle("Haptics", isOn: $hapticsEnabled)
                    Toggle("Show Hints", isOn: $hintsEnabled)
                } header: {
                    Text("Game")
                }

                Section {
                    LabeledContent("Stars", value: "\(game.progress.stars)")
                    LabeledContent("Game Balls", value: game.progress.gameBalls.formatted())
                    LabeledContent("Current Level", value: "\(game.progress.currentLevelNumber)")
                } header: {
                    Text("Progress")
                }

                Section {
                    Button(role: .destructive) {
                        showsResetConfirm = true
                    } label: {
                        Text("Reset Progress")
                    }
                } header: {
                    Text("Danger Zone")
                } footer: {
                    Text("Wipes cleared levels, stars, Game Balls and XP. This cannot be undone.")
                }
            }
            .tint(Palette.accent)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog(
                "Reset all progress?",
                isPresented: $showsResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset Everything", role: .destructive) {
                    game.resetProgress()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your whole career starts over from Level 1.")
            }
        }
    }
}
