import SwiftUI

/// Grid tile for a single locker cosmetic.
struct LockerItemCard: View {
    let item: CosmeticItem
    var onTap: (CosmeticItem) -> Void

    var body: some View {
        Button {
            onTap(item)
        } label: {
            VStack(spacing: 10) {
                CosmeticPreviewView(preview: item.preview)
                    .frame(height: 92)
                    .opacity(item.isOwned ? 1 : 0.55)
                    .overlay {
                        if !item.isOwned {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Palette.chalk.opacity(0.9))
                                .padding(8)
                                .background {
                                    Circle().fill(Palette.canvasDeep.opacity(0.72))
                                }
                        }
                    }

                footer
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Palette.surface.opacity(0.92))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                item.isEquipped ? Palette.accent : Palette.stroke,
                                lineWidth: item.isEquipped ? 2 : 1
                            )
                    }
                    .shadow(
                        color: item.isEquipped ? Palette.accent.opacity(0.45) : .black.opacity(0.35),
                        radius: item.isEquipped ? 14 : 6,
                        y: 4
                    )
            }
        }
        .buttonStyle(NodePressStyle())
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        if item.isEquipped { return "\(item.name), equipped" }
        if item.isOwned { return "\(item.name), owned" }
        return "\(item.name), locked, costs \(item.price) game balls"
    }

    @ViewBuilder
    private var footer: some View {
        if item.isEquipped {
            Text("EQUIPPED")
                .broadcastLabel(10, weight: .heavy)
                .foregroundStyle(Palette.chalk)
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background {
                    Capsule().fill(Palette.accent)
                }
        } else if item.isOwned {
            Text(item.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.chalk)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        } else {
            HStack(spacing: 5) {
                FootballIcon(size: 17)
                Text("\(item.price)")
                    .scoreboardNumber(13)
                    .foregroundStyle(Palette.chalk)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background {
                Capsule()
                    .fill(Palette.canvasDeep.opacity(0.85))
                    .overlay { Capsule().stroke(Palette.stroke, lineWidth: 1) }
            }
        }
    }
}

/// Renders each cosmetic category's preview art.
nonisolated struct CosmeticPreviewView: View {
    let preview: CosmeticPreview

    var body: some View {
        switch preview {
        case .helmet(let shell, let facemask, let stripe):
            HelmetGlyph(shell: shell, facemask: facemask, stripe: stripe)
                .padding(.horizontal, 6)

        case .uniform(let jersey, let trim):
            JerseyGlyph(jersey: jersey, trim: trim)

        case .turf(let primary, let secondary):
            TurfBackdrop(primary: primary, secondary: secondary, showsNumbers: false, stripeCount: 5)
                .clipShape(.rect(cornerRadius: 10))

        case .stadiumLights(let tint):
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Palette.canvasDeep, Palette.surfaceRaised],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                HStack(spacing: 16) {
                    FloodlightBank(tint: tint)
                    FloodlightBank(tint: tint)
                }
                .scaleEffect(0.85)
            }

        case .marker(let symbol, let tint), .celebration(let symbol, let tint):
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.opacity(0.14))
                Image(systemName: symbol)
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(tint)
                    .shadow(color: tint.opacity(0.6), radius: 10)
            }
        }
    }
}

/// Simple jersey silhouette for uniform tiles.
nonisolated struct JerseyGlyph: View {
    let jersey: Color
    let trim: Color

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let width = min(size.width, size.height * 1.05)
            let height = size.height

            ZStack {
                JerseyShape()
                    .fill(
                        LinearGradient(
                            colors: [jersey, jersey.opacity(0.72)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay {
                        JerseyShape().stroke(trim.opacity(0.85), lineWidth: 2)
                    }

                Text("00")
                    .broadcastHeadline(height * 0.3, tracking: 1)
                    .foregroundStyle(trim)
                    .offset(y: height * 0.06)
            }
            .frame(width: width, height: height)
            .frame(maxWidth: .infinity)
        }
    }
}

/// Football jersey outline with shoulder flares.
nonisolated struct JerseyShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width * 0.26, y: height * 0.08))
        path.addLine(to: CGPoint(x: width * 0.40, y: height * 0.06))
        path.addQuadCurve(
            to: CGPoint(x: width * 0.60, y: height * 0.06),
            control: CGPoint(x: width * 0.50, y: height * 0.18)
        )
        path.addLine(to: CGPoint(x: width * 0.74, y: height * 0.08))
        path.addLine(to: CGPoint(x: width * 0.90, y: height * 0.34))
        path.addLine(to: CGPoint(x: width * 0.76, y: height * 0.44))
        path.addLine(to: CGPoint(x: width * 0.76, y: height * 0.94))
        path.addLine(to: CGPoint(x: width * 0.24, y: height * 0.94))
        path.addLine(to: CGPoint(x: width * 0.24, y: height * 0.44))
        path.addLine(to: CGPoint(x: width * 0.10, y: height * 0.34))
        path.closeSubpath()
        return path
    }
}
