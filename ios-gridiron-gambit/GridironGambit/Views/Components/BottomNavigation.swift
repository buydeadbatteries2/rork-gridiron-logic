import SwiftUI

/// Custom floating tab bar shared by every top-level screen.
struct BottomNavigation: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background {
            Capsule(style: .continuous)
                .fill(Palette.surface.opacity(0.9))
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(Palette.stroke.opacity(0.9), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.55), radius: 18, y: 8)
        }
        .padding(.horizontal, 24)
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let isSelected = selection == tab

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                selection = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.symbol)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(isSelected ? Palette.accentBright : Palette.muted)
                    .shadow(color: isSelected ? Palette.accent.opacity(0.7) : .clear, radius: 8)

                Text(tab.rawValue.uppercased())
                    .broadcastLabel(10, weight: isSelected ? .heavy : .semibold)
                    .foregroundStyle(isSelected ? Palette.accentBright : Palette.muted)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(Palette.fieldDeep.opacity(0.55))
                        .overlay {
                            Capsule(style: .continuous)
                                .stroke(Palette.fieldLight.opacity(0.35), lineWidth: 1)
                        }
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.rawValue)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}
