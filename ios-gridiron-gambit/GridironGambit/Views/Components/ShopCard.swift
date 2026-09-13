import SwiftUI

/// Game Ball currency pack tile.
struct ShopCard: View {
    let pack: GameBallPack
    var onTap: (GameBallPack) -> Void

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0x1A2B42), Color(hex: 0x0E1726)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RadialGradient(
                            colors: [Color(hex: 0xDCEBFF).opacity(0.16), .clear],
                            center: UnitPoint(x: 0.2, y: 0.1),
                            startRadius: 2,
                            endRadius: 120
                        )
                    }

                BallPile(count: pack.ballCount)
                    .padding(10)

                VStack {
                    HStack {
                        Spacer()
                        if let bonus = pack.bonusLabel {
                            Text(bonus.uppercased())
                                .broadcastLabel(8, weight: .heavy)
                                .foregroundStyle(Palette.canvasDeep)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background { Capsule().fill(Palette.gold) }
                        }
                    }
                    Spacer()
                }
                .padding(8)
            }
            .frame(height: 104)
            .clipShape(.rect(cornerRadius: 12))

            VStack(spacing: 1) {
                Text(pack.amount.formatted())
                    .broadcastHeadline(30, tracking: 0.5)
                    .foregroundStyle(Palette.chalk)
                Text("GAME BALLS")
                    .broadcastLabel(9)
                    .foregroundStyle(Palette.muted)
            }

            Button {
                onTap(pack)
            } label: {
                Text(pack.price)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(Palette.chalk)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Palette.accentBright, Palette.accent],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Palette.accent.opacity(0.5), radius: 10, y: 3)
                    }
            }
            .buttonStyle(NodePressStyle())
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Palette.surface.opacity(0.92))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Palette.stroke, lineWidth: 1)
                }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pack.amount) game balls for \(pack.price)")
    }
}

/// Stack of footballs illustrating pack size.
nonisolated struct BallPile: View {
    let count: Int

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let ballWidth = size.width * (count > 2 ? 0.42 : 0.5)

            ZStack {
                ForEach(0..<min(count, 4), id: \.self) { index in
                    FootballIcon(size: ballWidth)
                        .rotationEffect(.degrees(Double(index) * 13 - 16))
                        .offset(
                            x: CGFloat(index % 2 == 0 ? -1 : 1) * CGFloat(index) * size.width * 0.09,
                            y: CGFloat(index) * -size.height * 0.08
                        )
                }
            }
            .frame(width: size.width, height: size.height)
        }
    }
}

/// Bundle / unlock offer card.
struct ShopOfferCard: View {
    let offer: ShopOffer
    var onTap: (ShopOffer) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: offer.symbol)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(offer.highlighted ? Palette.gold : Palette.blue)
                    .frame(width: 38, height: 38)
                    .background {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill((offer.highlighted ? Palette.gold : Palette.blue).opacity(0.16))
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(offer.title)
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(Palette.chalk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(offer.subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Palette.muted)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 5) {
                ForEach(offer.perks, id: \.self) { perk in
                    HStack(spacing: 7) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(Palette.fieldLight)
                        Text(perk)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Palette.chalk.opacity(0.85))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                }
            }

            Button {
                onTap(offer)
            } label: {
                Text(offer.price)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(Palette.chalk)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Palette.accentBright, Palette.accent],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Palette.accent.opacity(0.45), radius: 8, y: 3)
                    }
            }
            .buttonStyle(NodePressStyle())
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Palette.surface.opacity(0.92))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            offer.highlighted ? Palette.gold.opacity(0.7) : Palette.stroke,
                            lineWidth: offer.highlighted ? 1.6 : 1
                        )
                }
                .shadow(
                    color: offer.highlighted ? Palette.gold.opacity(0.22) : .black.opacity(0.35),
                    radius: 12,
                    y: 5
                )
        }
    }
}
