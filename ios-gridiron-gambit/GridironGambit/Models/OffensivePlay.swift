import SwiftUI

/// Offensive personnel drawn on the field, positioned in normalized field space.
nonisolated struct OffensiveMarker: Identifiable, Sendable, Hashable {
    let id: String
    let label: String
    /// Normalized position, x and y in 0...1 where y = 0 is the defensive end zone.
    let point: CGPoint
    let isEligible: Bool
}

/// How a route is drawn and color-coded on the play diagram.
nonisolated enum RouteKind: String, Sendable {
    case vertical
    case crossing
    case checkdown

    var color: Color {
        switch self {
        case .vertical: Palette.accent
        case .crossing: Palette.gold
        case .checkdown: Palette.blue
        }
    }
}

/// A receiver's route, expressed as normalized waypoints.
nonisolated struct OffensiveRoute: Identifiable, Sendable, Hashable {
    let id: String
    let kind: RouteKind
    let points: [CGPoint]
}

/// Game-situation context shown above the field.
nonisolated struct PlaySituation: Sendable, Hashable {
    let levelNumber: Int
    let down: String
    let ballOn: String
    let playClock: Int
    let playName: String
}

/// The offensive side of a puzzle: the themed play diagram drawn above the
/// defensive grid. Purely presentational — no solving knowledge required.
nonisolated struct OffensivePlay: Sendable, Hashable {
    let situation: PlaySituation
    let markers: [OffensiveMarker]
    let routes: [OffensiveRoute]
    /// Normalized y of the line of scrimmage.
    let lineOfScrimmage: CGFloat
}
