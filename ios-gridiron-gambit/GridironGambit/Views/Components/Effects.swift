import SwiftUI

/// Horizontal shake used for wrong "Confirm the Call" attempts.
/// Animate `animatableData` from its previous value to trigger the motion.
nonisolated struct ShakeEffect: GeometryEffect {
    var travel: CGFloat = 7
    var shakes: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let offset = travel * sin(animatableData * .pi * shakes * 2)
        return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }
}

/// Reusable container that shakes whenever the trigger value changes.
struct Shaker<Value: Equatable>: ViewModifier {
    let trigger: Value
    @State private var animationValue: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(animatableData: animationValue))
            .onChange(of: trigger) { _, _ in
                withAnimation(.easeInOut(duration: 0.5)) {
                    animationValue += 1
                }
            }
    }
}

nonisolated extension View {
    /// Shakes the view each time `trigger` changes.
    func shaking<Value: Equatable>(on trigger: Value) -> some View {
        modifier(Shaker(trigger: trigger))
    }
}
