import SwiftUI

/// Reusable turf texture with yard lines, hash marks and optional yard numbers.
/// Drawn vertically: yard lines run horizontally across the view.
nonisolated struct TurfBackdrop: View {
    var primary: Color = Palette.field
    var secondary: Color = Palette.fieldDeep
    var showsNumbers: Bool = true
    var stripeCount: Int = 12

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let stripeHeight = size.height / CGFloat(stripeCount)

            ZStack {
                // Mown stripes
                VStack(spacing: 0) {
                    ForEach(0..<stripeCount, id: \.self) { index in
                        Rectangle()
                            .fill(index.isMultiple(of: 2) ? primary : secondary)
                            .frame(height: stripeHeight)
                    }
                }

                // Yard lines + hash marks
                Canvas { context, canvasSize in
                    let lineColor = Color.white.opacity(0.32)
                    let count = stripeCount
                    for index in 0...count {
                        let y = canvasSize.height / CGFloat(count) * CGFloat(index)
                        var line = Path()
                        line.move(to: CGPoint(x: canvasSize.width * 0.04, y: y))
                        line.addLine(to: CGPoint(x: canvasSize.width * 0.96, y: y))
                        context.stroke(line, with: .color(lineColor), lineWidth: 2)
                    }

                    // Hash marks between yard lines
                    let hashColor = Color.white.opacity(0.22)
                    let hashXs: [CGFloat] = [0.34, 0.66]
                    for index in 0..<count {
                        let bandTop = canvasSize.height / CGFloat(count) * CGFloat(index)
                        let bandHeight = canvasSize.height / CGFloat(count)
                        for step in 1..<5 {
                            let y = bandTop + bandHeight * CGFloat(step) / 5
                            for hashX in hashXs {
                                var hash = Path()
                                hash.move(to: CGPoint(x: canvasSize.width * hashX - 5, y: y))
                                hash.addLine(to: CGPoint(x: canvasSize.width * hashX + 5, y: y))
                                context.stroke(hash, with: .color(hashColor), lineWidth: 1.5)
                            }
                        }
                    }

                    // Sidelines
                    for sideX in [CGFloat(0.04), CGFloat(0.96)] {
                        var side = Path()
                        side.move(to: CGPoint(x: canvasSize.width * sideX, y: 0))
                        side.addLine(to: CGPoint(x: canvasSize.width * sideX, y: canvasSize.height))
                        context.stroke(side, with: .color(Color.white.opacity(0.4)), lineWidth: 3)
                    }
                }

                if showsNumbers {
                    YardNumbers(stripeCount: stripeCount)
                }
            }
            .frame(width: size.width, height: size.height)
        }
    }
}

/// Large sideline yard numbers, mirrored on both edges.
nonisolated struct YardNumbers: View {
    var stripeCount: Int

    private var numbers: [Int] {
        // 50, 40, 30, 20, 10 repeated down the field.
        let sequence = [50, 40, 30, 20, 10]
        var result: [Int] = []
        while result.count < stripeCount / 2 {
            result.append(contentsOf: sequence)
        }
        return Array(result.prefix(max(1, stripeCount / 2)))
    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let spacing = size.height / CGFloat(numbers.count)

            ForEach(Array(numbers.enumerated()), id: \.offset) { index, number in
                let y = spacing * (CGFloat(index) + 0.5)
                HStack {
                    Text("\(number)")
                        .broadcastHeadline(34, tracking: 0)
                        .foregroundStyle(Color.white.opacity(0.26))
                    Spacer()
                    Text("\(number)")
                        .broadcastHeadline(34, tracking: 0)
                        .foregroundStyle(Color.white.opacity(0.26))
                }
                .padding(.horizontal, size.width * 0.08)
                .position(x: size.width / 2, y: y)
            }
        }
    }
}

/// Night-sky gradient with stadium light bloom used behind chrome-heavy screens.
nonisolated struct StadiumSkyBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Palette.canvasDeep, Palette.canvas, Color(hex: 0x16233A)],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [Color(hex: 0x9FC6FF).opacity(0.22), .clear],
                center: UnitPoint(x: 0.08, y: 0.06),
                startRadius: 4,
                endRadius: 260
            )

            RadialGradient(
                colors: [Color(hex: 0x9FC6FF).opacity(0.22), .clear],
                center: UnitPoint(x: 0.92, y: 0.06),
                startRadius: 4,
                endRadius: 260
            )
        }
        .ignoresSafeArea()
    }
}

/// A bank of stadium floodlights.
nonisolated struct FloodlightBank: View {
    var tint: Color = Color(hex: 0xF4F8FF)

    var body: some View {
        VStack(spacing: 3) {
            ForEach(0..<2, id: \.self) { _ in
                HStack(spacing: 3) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(tint)
                            .frame(width: 9, height: 7)
                            .shadow(color: tint.opacity(0.9), radius: 6)
                    }
                }
            }
        }
        .padding(4)
        .background {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Palette.canvasDeep.opacity(0.7))
        }
        .shadow(color: tint.opacity(0.55), radius: 26)
    }
}
