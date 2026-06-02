import SwiftUI

/// FUT-style holographic shine that follows device tilt (gyroscope / attitude).
struct CardHolographicEffect: View {
    @StateObject private var motion = DeviceMotionObserver()

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let dx = motion.roll * w * 0.55
            let dy = motion.pitch * h * 0.55

            ZStack {
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.55),
                        Color.white.opacity(0.12),
                        Color.clear,
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: w * 0.45
                )
                .frame(width: w * 1.1, height: h * 0.7)
                .offset(x: dx, y: dy - h * 0.08)
                .blendMode(.plusLighter)

                LinearGradient(
                    colors: [
                        Color(red: 1, green: 0.45, blue: 0.2).opacity(0.35),
                        Color(red: 1, green: 0.92, blue: 0.4).opacity(0.5),
                        Color(red: 0.55, green: 0.85, blue: 1).opacity(0.35),
                        Color(red: 0.95, green: 0.5, blue: 0.95).opacity(0.3),
                        Color.clear,
                    ],
                    startPoint: UnitPoint(x: 0.15 + Double(motion.roll) * 0.35, y: 0.1 + Double(motion.pitch) * 0.2),
                    endPoint: UnitPoint(x: 0.85 + Double(motion.roll) * 0.2, y: 0.9 + Double(motion.pitch) * 0.25)
                )
                .opacity(0.65)
                .blendMode(.screen)

                LinearGradient(
                    colors: [Color.clear, Color.white.opacity(0.22), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(-18 + Double(motion.roll) * 28))
                .offset(x: dx * 0.6, y: dy * 0.35)
                .blendMode(.overlay)
            }
        }
        .allowsHitTesting(false)
        .onAppear { motion.start() }
        .onDisappear { motion.stop() }
    }
}

/// Gold FUT card outline (rounded shield-like rectangle).
struct FUTCardShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let topR = w * 0.09
        let bottomR = w * 0.11

        var path = Path()
        path.move(to: CGPoint(x: topR, y: 0))
        path.addLine(to: CGPoint(x: w - topR, y: 0))
        path.addQuadCurve(to: CGPoint(x: w, y: topR), control: CGPoint(x: w, y: 0))
        path.addLine(to: CGPoint(x: w, y: h - bottomR))
        path.addQuadCurve(to: CGPoint(x: w - bottomR, y: h), control: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: bottomR, y: h))
        path.addQuadCurve(to: CGPoint(x: 0, y: h - bottomR), control: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: 0, y: topR))
        path.addQuadCurve(to: CGPoint(x: topR, y: 0), control: CGPoint(x: 0, y: 0))
        path.closeSubpath()
        return path
    }
}

enum FUTCardPalette {
    static let goldTop = Color(red: 1, green: 0.92, blue: 0.55)
    static let goldMid = Color(red: 0.92, green: 0.68, blue: 0.18)
    static let goldDeep = Color(red: 0.62, green: 0.38, blue: 0.05)
    static let innerField = Color(red: 0.06, green: 0.07, blue: 0.09)
    static let namePlate = LinearGradient(
        colors: [
            Color(red: 0.98, green: 0.82, blue: 0.35),
            Color(red: 0.78, green: 0.52, blue: 0.08),
            Color(red: 0.55, green: 0.32, blue: 0.02),
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    static let goldFrame = LinearGradient(
        colors: [goldTop, goldMid, goldDeep, goldMid, goldTop],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
