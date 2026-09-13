import SwiftUI

/// SHOP tab: Game Ball packs and bundle offers. UI only in Phase 1.
struct ShopScreen: View {
    @Environment(GameState.self) private var game

    @State private var showsSettings: Bool = false
    @State private var pendingPurchase: String?

    private let packColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack(alignment: .top) {
            backdrop

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    SectionHeader(title: "Game Balls", caption: "Fuel your strategy")

                    LazyVGrid(columns: packColumns, spacing: 12) {
                        ForEach(MockData.gameBallPacks) { pack in
                            ShopCard(pack: pack) { tapped in
                                pendingPurchase = "\(tapped.amount.formatted()) Game Balls"
                            }
                        }
                    }
                    .padding(.horizontal, 14)

                    SectionHeader(title: "Other", caption: "More ways to win")

                    VStack(spacing: 12) {
                        ForEach(MockData.shopOffers) { offer in
                            ShopOfferCard(offer: offer) { tapped in
                                pendingPurchase = tapped.title
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
            "Coming Soon",
            isPresented: Binding(
                get: { pendingPurchase != nil },
                set: { if !$0 { pendingPurchase = nil } }
            )
        ) {
            Button("OK", role: .cancel) { pendingPurchase = nil }
        } message: {
            Text("\(pendingPurchase ?? "This offer") will be purchasable in a future update.")
        }
    }

    private var backdrop: some View {
        ZStack {
            StadiumSkyBackdrop()

            VStack {
                Spacer()
                TurfBackdrop(showsNumbers: false, stripeCount: 4)
                    .frame(height: 180)
                    .overlay {
                        LinearGradient(
                            colors: [Palette.canvasDeep, Palette.canvasDeep.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
            }
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SHOP")
                    .broadcastHeadline(42, tracking: 2)
                    .foregroundStyle(Palette.chalk)
                Text("GEAR UP. PLAY BIGGER.")
                    .broadcastLabel(10)
                    .foregroundStyle(Palette.muted)
            }

            Spacer()

            FloodlightBank()
        }
        .padding(.horizontal, 18)
    }
}

/// Broadcast-style section divider with a trailing caption.
nonisolated struct SectionHeader: View {
    let title: String
    let caption: String

    var body: some View {
        HStack(spacing: 12) {
            Text(title.uppercased())
                .broadcastHeadline(24, tracking: 2)
                .foregroundStyle(Palette.chalk)

            Rectangle()
                .fill(Palette.stroke)
                .frame(height: 1)

            Text(caption.uppercased())
                .broadcastLabel(9)
                .foregroundStyle(Palette.muted)
        }
        .padding(.horizontal, 18)
    }
}
