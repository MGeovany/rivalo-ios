import SwiftUI

/// FUT-style shield silhouette.
struct FUTCardShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let topR = w * 0.085
        let bottomR = w * 0.13
        let sideTaper = w * 0.028

        var path = Path()
        path.move(to: CGPoint(x: topR, y: 0))
        path.addLine(to: CGPoint(x: w - topR, y: 0))
        path.addQuadCurve(to: CGPoint(x: w, y: topR), control: CGPoint(x: w, y: 0))
        path.addLine(to: CGPoint(x: w - sideTaper, y: h - bottomR))
        path.addQuadCurve(to: CGPoint(x: w - bottomR, y: h), control: CGPoint(x: w - sideTaper * 1.4, y: h))
        path.addLine(to: CGPoint(x: bottomR, y: h))
        path.addQuadCurve(to: CGPoint(x: sideTaper, y: h - bottomR), control: CGPoint(x: sideTaper * 1.4, y: h))
        path.addLine(to: CGPoint(x: 0, y: topR))
        path.addQuadCurve(to: CGPoint(x: topR, y: 0), control: CGPoint(x: 0, y: 0))
        path.closeSubpath()
        return path
    }
}

extension PlayerCardRank {
    /// Wing/ribbon layer count — grows with rank tier.
    var ribbonLayers: Int {
        switch self {
        case .unranked: 1
        case .bronze: 2
        case .silver: 2
        case .gold: 3
        case .platinum: 3
        case .emerald: 4
        case .diamond: 5
        case .holographic: 6
        }
    }
}

/// LoL-style wing ribbons framing the player portrait — complexity scales with rank.
struct RankRibbonFrame: View {
    let rank: PlayerCardRank
    let style: PlayerCardRankStyle

    var body: some View {
        Canvas { context, size in
            let cx = size.width * 0.5
            let cy = size.height * 0.36
            let layers = rank.ribbonLayers

            for layer in 0 ..< layers {
                let scale = 1.0 - CGFloat(layer) * 0.07
                let opacity = 0.95 - Double(layer) * 0.1
                let wingColor = layer == 0 ? style.accentBright : style.accent

                drawWing(
                    context: &context,
                    anchor: CGPoint(x: cx, y: cy),
                    size: size,
                    side: .left,
                    scale: scale,
                    layer: layer,
                    color: wingColor.opacity(opacity)
                )
                drawWing(
                    context: &context,
                    anchor: CGPoint(x: cx, y: cy),
                    size: size,
                    side: .right,
                    scale: scale,
                    layer: layer,
                    color: wingColor.opacity(opacity)
                )
            }

            if layers >= 2 {
                drawCrest(context: &context, center: CGPoint(x: cx, y: cy + size.height * 0.22), width: size.width * 0.42, style: style, layers: layers)
            }
        }
        .allowsHitTesting(false)
    }

    private enum Side { case left, right }

    private func drawWing(
        context: inout GraphicsContext,
        anchor: CGPoint,
        size: CGSize,
        side: Side,
        scale: CGFloat,
        layer: Int,
        color: Color
    ) {
        let w = size.width
        let h = size.height
        let direction: CGFloat = side == .left ? -1 : 1
        let spread = (0.28 + CGFloat(layer) * 0.045) * scale
        let lift = (0.12 + CGFloat(layer) * 0.03) * scale

        var path = Path()
        path.move(to: CGPoint(x: anchor.x + direction * w * 0.04, y: anchor.y + h * 0.1))

        path.addQuadCurve(
            to: CGPoint(x: anchor.x + direction * w * spread, y: anchor.y - h * lift),
            control: CGPoint(x: anchor.x + direction * w * (spread * 0.35), y: anchor.y + h * 0.02)
        )
        path.addQuadCurve(
            to: CGPoint(x: anchor.x + direction * w * (spread + 0.04), y: anchor.y + h * 0.08),
            control: CGPoint(x: anchor.x + direction * w * (spread + 0.02), y: anchor.y - h * 0.02)
        )
        path.addQuadCurve(
            to: CGPoint(x: anchor.x + direction * w * (spread * 0.62), y: anchor.y + h * 0.2),
            control: CGPoint(x: anchor.x + direction * w * (spread + 0.06), y: anchor.y + h * 0.14)
        )
        path.addQuadCurve(
            to: CGPoint(x: anchor.x + direction * w * 0.06, y: anchor.y + h * 0.16),
            control: CGPoint(x: anchor.x + direction * w * (spread * 0.35), y: anchor.y + h * 0.24)
        )
        path.closeSubpath()

        context.fill(path, with: .linearGradient(
            Gradient(colors: [color, style.frameDeep.opacity(0.9)]),
            startPoint: CGPoint(x: anchor.x, y: anchor.y - h * 0.12),
            endPoint: CGPoint(x: anchor.x + direction * w * spread, y: anchor.y + h * 0.18)
        ))

        context.stroke(path, with: .color(style.frameTop.opacity(0.5)), lineWidth: 1)
    }

    private func drawCrest(
        context: inout GraphicsContext,
        center: CGPoint,
        width: CGFloat,
        style: PlayerCardRankStyle,
        layers: Int
    ) {
        let halfW = width * 0.55
        let height = width * 0.22 + width * 0.06 * CGFloat(layers)

        var path = Path()
        path.move(to: CGPoint(x: center.x, y: center.y - height * 0.5))
        path.addLine(to: CGPoint(x: center.x - halfW * 0.85, y: center.y + height * 0.05))
        path.addLine(to: CGPoint(x: center.x - halfW * 0.35, y: center.y + height * 0.35))
        path.addLine(to: CGPoint(x: center.x, y: center.y + height * 0.55))
        path.addLine(to: CGPoint(x: center.x + halfW * 0.35, y: center.y + height * 0.35))
        path.addLine(to: CGPoint(x: center.x + halfW * 0.85, y: center.y + height * 0.05))
        path.closeSubpath()

        context.fill(path, with: .linearGradient(
            Gradient(colors: [style.accentBright, style.frameMid, style.frameDeep]),
            startPoint: CGPoint(x: center.x, y: center.y - height * 0.4),
            endPoint: CGPoint(x: center.x, y: center.y + height * 0.5)
        ))
        context.stroke(path, with: .color(Color.white.opacity(0.4)), lineWidth: 1.2)
    }
}
