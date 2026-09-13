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

    /// Horizontal shake for a blown assignment: fires only on the cell that
    /// is being undone, whenever a new blown-assignment token arrives.
    func blownShake(isActive: Bool, token: Int) -> some View {
        modifier(BlownShakeModifier(isActive: isActive, token: token))
    }
}

/// Container for the blown-assignment shake.
struct BlownShakeModifier: ViewModifier {
    let isActive: Bool
    let token: Int
    @State private var animationValue: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(travel: 6, shakes: 3, animatableData: animationValue))
            .onChange(of: token) { _, _ in
                guard isActive else { return }
                withAnimation(.easeInOut(duration: 0.55)) {
                    animationValue += 1
                }
            }
    }
}
