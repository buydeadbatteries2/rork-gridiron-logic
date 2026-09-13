import SwiftUI

/// LOCKER tab: "MY DEFENSE" cosmetic customization.
struct LockerScreen: View {
    @Environment(GameState.self) private var game

    @State private var selectedCategory: LockerCategory = .helmet
    @State private var showsSettings: Bool = false
    @State private var lockedItemName: String?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack(alignment: .top) {
            backdrop

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    header
                    categoryChips

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(game.cosmetics(in: selectedCategory)) { item in
                            LockerItemCard(item: item) { tapped in
                                if tapped.isOwned {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        game.equip(tapped)
                                    }
                                } else {
                                    lockedItemName = tapped.name
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                }
                .padding(.top, 68)
                .padding(.bottom, 130)
            }
        }
        .overlay(alignment: .top) {
            TopStatusBar(progress: game.progress) { showsSettings = true }
                .background {
                    LinearGradient(
                        colors: [Palette.canvasDeep.opacity(0.98), Palette.canvasDeep.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(edges: .top)
                }
        }
        .sheet(isPresented: $showsSettings) { SettingsSheet() }
        .alert(
            "Locked",
            isPresented: Binding(
                get: { lockedItemName != nil },
                set: { if !$0 { lockedItemName = nil } }
            )
        ) {
            Button("OK", role: .cancel) { lockedItemName = nil }
        } message: {
            Text("\(lockedItemName ?? "This item") unlocks with Game Balls in a future update.")
        }
    }

    private var backdrop: some View {
        ZStack {
            StadiumSkyBackdrop()

            VStack {
                Spacer()
                TurfBackdrop(showsNumbers: false, stripeCount: 4)
                    .frame(height: 200)
                    .overlay {
                        LinearGradient(
                            colors: [Palette.canvasDeep, Palette.canvasDeep.opacity(0.25)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
            }
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            HStack(spacing: 14) {
                FloodlightBank()
                Spacer()
                FloodlightBank()
            }
            .padding(.horizontal, 22)

            Text("MY DEFENSE")
                .broadcastHeadline(38, tracking: 3)
                .foregroundStyle(Palette.chalk)
                .shadow(color: .black.opacity(0.7), radius: 8, y: 2)

            Text("Build the look. Earn the respect.")
                .broadcastLabel(10)
                .foregroundStyle(Palette.muted)
        }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(LockerCategory.allCases) { category in
                    let isSelected = category == selectedCategory
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedCategory = category
                        }
                    } label: {
                        Text(category.rawValue)
                            .font(.system(size: 14, weight: isSelected ? .heavy : .semibold))
                            .foregroundStyle(isSelected ? Palette.chalk : Palette.muted)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background {
                                Capsule()
                                    .fill(isSelected ? Palette.accent : Color.clear)
                                    .shadow(
                                        color: isSelected ? Palette.accent.opacity(0.5) : .clear,
                                        radius: 10,
                                        y: 3
                                    )
                            }
                    }
                    .buttonStyle(NodePressStyle())
                }
            }
        }
        .contentMargins(.horizontal, 16, for: .scrollContent)
    }
}
