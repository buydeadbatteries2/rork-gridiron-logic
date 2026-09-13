import SwiftUI

/// The stadium destination graphic anchored at the top of a chapter road.
struct StadiumMarquee: View {
    let stadium: Stadium
    let playsRemaining: Int

    var body: some View {
        ZStack(alignment: .bottom) {
            StadiumSilhouette()
                .frame(height: 210)

            VStack(spacing: 8) {
                Text(stadium.name)
                    .broadcastHeadline(38, tracking: 3)
                    .foregroundStyle(Palette.chalk)
                    .shadow(color: .black.opacity(0.8), radius: 8, y: 2)

                Text(stadium.tagline)
                    .broadcastHeadline(20, tracking: 4)
                    .foregroundStyle(Palette.muted)

                Text("\(playsRemaining) PLAYS TO THE STADIUM")
                    .broadcastLabel(12, weight: .heavy)
                    .foregroundStyle(Palette.chalk)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background {
                        Capsule(style: .continuous)
                            .fill(Palette.canvasDeep.opacity(0.75))
                            .overlay {
                                Capsule(style: .continuous)
                                    .stroke(Palette.accent.opacity(0.65), lineWidth: 1.2)
                            }
                    }
                    .padding(.top, 2)
            }
            .padding(.bottom, 26)

            HStack {
                BannerFlag(text: stadium.leftBanner)
                Spacer()
                BannerFlag(text: stadium.rightBanner)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Layered press-box / grandstand silhouette with floodlights.
nonisolated struct StadiumSilhouette: View {
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            ZStack {
                // Upper deck arc
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0x1A2739), Color(hex: 0x0C1420)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size.width * 1.5, height: size.height * 1.25)
                    .offset(y: size.height * 0.28)

                // Crowd speckle bands
                VStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { row in
                        CrowdBand(seed: row)
                            .frame(height: 10)
                    }
                }
                .frame(width: size.width * 0.92)
                .offset(y: size.height * 0.12)
                .opacity(0.5)

                // Press box
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(hex: 0x101A29))
                    .frame(width: size.width * 0.72, height: size.height * 0.42)
                    .overlay {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    }
                    .offset(y: -size.height * 0.06)

                // Floodlights
                HStack {
                    FloodlightBank()
                    Spacer()
                    FloodlightBank()
                }
                .frame(width: size.width * 0.96)
                .offset(y: -size.height * 0.34)
            }
            .frame(width: size.width, height: size.height, alignment: .center)
        }
    }
}

/// Speckled crowd row rendered with deterministic pseudo-random dots.
nonisolated struct CrowdBand: View {
    let seed: Int

    var body: some View {
        Canvas { context, size in
            var value = UInt64(seed &* 7919 &+ 104_729)
            let dotCount = Int(size.width / 6)
            for index in 0..<dotCount {
                value = value &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
                let normalized = Double((value >> 33) % 1000) / 1000
                let x = (size.width / CGFloat(dotCount)) * CGFloat(index)
                let y = size.height * CGFloat(normalized)
                let tint: Color = normalized > 0.7 ? Palette.accent.opacity(0.6) : Color.white.opacity(0.35)
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: 3, height: 3)),
                    with: .color(tint)
                )
            }
        }
    }
}

/// Vertical banner flag hung from the stadium facade.
nonisolated struct BannerFlag: View {
    let text: String

    var body: some View {
        VStack(spacing: 6) {
            FootballIcon(size: 22)

            Text(text.uppercased())
                .broadcastLabel(9, weight: .heavy)
                .foregroundStyle(Palette.chalk.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .frame(width: 74)
        .background {
            BannerShape()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0xA3202F), Color(hex: 0x6C1220)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    BannerShape()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.5), radius: 8, y: 4)
        }
    }
}

/// Pennant shape with a notched bottom edge.
nonisolated struct BannerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let notch = rect.height * 0.1
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - notch))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - notch))
        path.closeSubpath()
        return path
    }
}
