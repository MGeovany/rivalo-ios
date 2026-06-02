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

/// Dark textured background with diagonal streaks and sparks.
struct PlayerCardAmbientBackground: View {
    let style: PlayerCardRankStyle

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [style.innerTint, Color(red: 0.03, green: 0.03, blue: 0.04)],
                startPoint: .top,
                endPoint: .bottom
            )

            Canvas { context, size in
                for index in 0 ..< 7 {
                    let offset = CGFloat(index) * 0.14
                    var path = Path()
                    path.move(to: CGPoint(x: -size.width * 0.2, y: size.height * offset))
                    path.addLine(to: CGPoint(x: size.width * 1.2, y: size.height * (offset + 0.35)))
                    context.stroke(
                        path,
                        with: .color(style.accent.opacity(0.04)),
                        lineWidth: 1.2
                    )
                }

                let sparks: [(CGFloat, CGFloat, CGFloat)] = [
                    (0.18, 0.22, 1.2), (0.72, 0.18, 0.9), (0.45, 0.42, 1.5),
                    (0.82, 0.55, 1.0), (0.28, 0.62, 1.3), (0.58, 0.28, 0.8),
                ]
                for (x, y, r) in sparks {
                    let rect = CGRect(
                        x: size.width * x - r,
                        y: size.height * y - r,
                        width: r * 2,
                        height: r * 2
                    )
                    context.fill(Path(ellipseIn: rect), with: .color(style.accentBright.opacity(0.35)))
                }
            }
        }
    }
}

/// Ornate metallic frame with wing ribbons, gem crests, and tier-colored accents.
struct PlayerCardOrnateFrame: View {
    let rank: PlayerCardRank
    let style: PlayerCardRankStyle

    var body: some View {
        Canvas { context, size in
            drawOuterFrame(context: &context, size: size)
            drawTopGem(context: &context, center: CGPoint(x: size.width * 0.5, y: size.height * 0.018))
            drawBottomGem(context: &context, center: CGPoint(x: size.width * 0.5, y: size.height * 0.982))
            drawSideWings(context: &context, size: size)
            drawBottomWingCrest(context: &context, size: size)
        }
        .allowsHitTesting(false)
    }

    private func drawOuterFrame(context: inout GraphicsContext, size: CGSize) {
        let inset: CGFloat = 3
        let rect = CGRect(x: inset, y: inset, width: size.width - inset * 2, height: size.height - inset * 2)
        let path = FUTCardShape().path(in: rect)
        context.stroke(
            path,
            with: .linearGradient(
                Gradient(colors: [style.frameTop, style.frameMid, style.frameDeep, style.frameMid, style.frameTop]),
                startPoint: CGPoint(x: rect.minX, y: rect.minY),
                endPoint: CGPoint(x: rect.maxX, y: rect.maxY)
            ),
            lineWidth: 5
        )
        context.stroke(path, with: .color(Color.white.opacity(0.22)), lineWidth: 1)
    }

    private func drawTopGem(context: inout GraphicsContext, center: CGPoint) {
        let gem = diamondPath(center: center, width: 14, height: 18)
        context.fill(gem, with: .linearGradient(
            Gradient(colors: [style.accentBright, style.accent, style.frameDeep]),
            startPoint: CGPoint(x: center.x, y: center.y - 10),
            endPoint: CGPoint(x: center.x, y: center.y + 10)
        ))
        context.stroke(gem, with: .color(Color.white.opacity(0.5)), lineWidth: 0.8)
    }

    private func drawBottomGem(context: inout GraphicsContext, center: CGPoint) {
        let gem = diamondPath(center: center, width: 10, height: 12)
        context.fill(gem, with: .color(style.accent.opacity(0.85)))
    }

    private func drawSideWings(context: inout GraphicsContext, size: CGSize) {
        let cx = size.width * 0.5
        let cy = size.height * 0.38
        for layer in 0 ..< rank.ribbonLayers {
            let scale = 1.0 - CGFloat(layer) * 0.06
            let color = layer == 0 ? style.accentBright : style.accent
            drawWing(context: &context, anchor: CGPoint(x: cx, y: cy), size: size, side: .left, scale: scale, color: color.opacity(0.95 - Double(layer) * 0.08))
            drawWing(context: &context, anchor: CGPoint(x: cx, y: cy), size: size, side: .right, scale: scale, color: color.opacity(0.95 - Double(layer) * 0.08))
        }
    }

    private enum Side { case left, right }

    private func drawWing(
        context: inout GraphicsContext,
        anchor: CGPoint,
        size: CGSize,
        side: Side,
        scale: CGFloat,
        color: Color
    ) {
        let w = size.width
        let h = size.height
        let direction: CGFloat = side == .left ? -1 : 1
        let spread = 0.34 * scale
        let lift = 0.16 * scale

        var path = Path()
        path.move(to: CGPoint(x: anchor.x + direction * w * 0.05, y: anchor.y + h * 0.06))
        path.addQuadCurve(
            to: CGPoint(x: anchor.x + direction * w * spread, y: anchor.y - h * lift),
            control: CGPoint(x: anchor.x + direction * w * 0.12, y: anchor.y + h * 0.01)
        )
        path.addQuadCurve(
            to: CGPoint(x: anchor.x + direction * w * (spread + 0.05), y: anchor.y + h * 0.04),
            control: CGPoint(x: anchor.x + direction * w * (spread + 0.02), y: anchor.y - h * 0.03)
        )
        path.addQuadCurve(
            to: CGPoint(x: anchor.x + direction * w * (spread * 0.65), y: anchor.y + h * 0.22),
            control: CGPoint(x: anchor.x + direction * w * (spread + 0.08), y: anchor.y + h * 0.12)
        )
        path.addQuadCurve(
            to: CGPoint(x: anchor.x + direction * w * 0.07, y: anchor.y + h * 0.18),
            control: CGPoint(x: anchor.x + direction * w * 0.2, y: anchor.y + h * 0.28)
        )
        path.closeSubpath()

        context.fill(path, with: .linearGradient(
            Gradient(colors: [color, style.frameDeep.opacity(0.92)]),
            startPoint: CGPoint(x: anchor.x, y: anchor.y - h * 0.1),
            endPoint: CGPoint(x: anchor.x + direction * w * spread, y: anchor.y + h * 0.2)
        ))
        context.stroke(path, with: .color(style.frameTop.opacity(0.55)), lineWidth: 1)
    }

    private func drawBottomWingCrest(context: inout GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width * 0.5, y: size.height * 0.79)
        let halfW = size.width * 0.2
        let height = size.width * 0.07 + CGFloat(rank.ribbonLayers) * 2

        var path = Path()
        path.move(to: CGPoint(x: center.x, y: center.y - height))
        path.addLine(to: CGPoint(x: center.x - halfW * 0.9, y: center.y + height * 0.15))
        path.addLine(to: CGPoint(x: center.x - halfW * 0.35, y: center.y + height * 0.55))
        path.addLine(to: CGPoint(x: center.x, y: center.y + height * 0.75))
        path.addLine(to: CGPoint(x: center.x + halfW * 0.35, y: center.y + height * 0.55))
        path.addLine(to: CGPoint(x: center.x + halfW * 0.9, y: center.y + height * 0.15))
        path.closeSubpath()

        context.fill(path, with: .linearGradient(
            Gradient(colors: [style.accentBright, style.frameMid, style.frameDeep]),
            startPoint: CGPoint(x: center.x, y: center.y - height),
            endPoint: CGPoint(x: center.x, y: center.y + height)
        ))
        context.stroke(path, with: .color(Color.white.opacity(0.35)), lineWidth: 1)
    }

    private func diamondPath(center: CGPoint, width: CGFloat, height: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: center.x, y: center.y - height * 0.5))
        path.addLine(to: CGPoint(x: center.x + width * 0.5, y: center.y))
        path.addLine(to: CGPoint(x: center.x, y: center.y + height * 0.5))
        path.addLine(to: CGPoint(x: center.x - width * 0.5, y: center.y))
        path.closeSubpath()
        return path
    }
}

/// Small crest icon above the player name.
struct PlayerCardNameCrest: View {
    let style: PlayerCardRankStyle

    var body: some View {
        Canvas { context, size in
            let cx = size.width * 0.5
            let cy = size.height * 0.5
            let halfW = size.width * 0.42

            var path = Path()
            path.move(to: CGPoint(x: cx, y: cy - size.height * 0.35))
            path.addLine(to: CGPoint(x: cx - halfW, y: cy + size.height * 0.2))
            path.addLine(to: CGPoint(x: cx, y: cy + size.height * 0.35))
            path.addLine(to: CGPoint(x: cx + halfW, y: cy + size.height * 0.2))
            path.closeSubpath()

            context.fill(path, with: .linearGradient(
                Gradient(colors: [style.accentBright, style.frameMid]),
                startPoint: CGPoint(x: cx, y: 0),
                endPoint: CGPoint(x: cx, y: size.height)
            ))
        }
        .frame(width: 36, height: 18)
    }
}
