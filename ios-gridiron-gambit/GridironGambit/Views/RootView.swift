import SwiftUI

/// App shell: hosts the four top-level screens and the floating tab bar.
struct RootView: View {
    @State private var game = GameState()

    var body: some View {
        ZStack(alignment: .bottom) {
            Palette.canvasDeep.ignoresSafeArea()

            Group {
                switch game.selectedTab {
                case .road: RoadScreen()
                case .play: PlayScreen()
                case .locker: LockerScreen()
                case .shop: ShopScreen()
                }
            }
            .transition(.opacity)

            BottomNavigation(selection: Binding(
                get: { game.selectedTab },
                set: { game.selectedTab = $0 }
            ))
            .padding(.bottom, 6)
        }
        .environment(game)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    RootView()
}
