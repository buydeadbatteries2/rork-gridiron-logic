import SwiftUI

/// Broadcast-style typography helpers: compressed, heavy, wide-tracked capitals.
nonisolated extension View {
    /// Big scoreboard headline (stadium names, screen titles).
    func broadcastHeadline(_ size: CGFloat, tracking: CGFloat = 1.5) -> some View {
        font(.system(size: size, weight: .black))
            .fontWidth(.compressed)
            .tracking(tracking)
    }

    /// Small all-caps label used in scoreboard chrome and section headers.
    func broadcastLabel(_ size: CGFloat = 11, weight: Font.Weight = .bold) -> some View {
        font(.system(size: size, weight: weight))
            .tracking(1.6)
    }

    /// Numeric readouts (currency counters, level numbers, clocks).
    func scoreboardNumber(_ size: CGFloat) -> some View {
        font(.system(size: size, weight: .black, design: .default))
            .monospacedDigit()
    }
}

nonisolated extension Text {
    /// Uppercases the content for broadcast chrome.
    static func caps(_ value: String) -> Text {
        Text(value.uppercased())
    }
}
