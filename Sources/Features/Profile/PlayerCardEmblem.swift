import SwiftUI

/// Diamond gem matching the crests baked into the tier frame PNGs.
struct PlayerCardDiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let halfW = rect.width * 0.5
        let halfH = rect.height * 0.5

        path.move(to: CGPoint(x: center.x, y: center.y - halfH))
        path.addLine(to: CGPoint(x: center.x + halfW, y: center.y))
        path.addLine(to: CGPoint(x: center.x, y: center.y + halfH))
        path.addLine(to: CGPoint(x: center.x - halfW, y: center.y))
        path.closeSubpath()
        return path
    }
}

/// Tier-colored monogram drawn inside the card window (replaces the photo slot).
struct PlayerCardEmblem: View {
    let initials: String
    let style: PlayerCardRankStyle
    let canvasSize: CGSize

    private var width: CGFloat { canvasSize.width }
    private var area: CGRect { PlayerCardLayout.emblem.frame(in: canvasSize) }

    var body: some View {
        let diamond = PlayerCardDiamondShape()
        let glowSize = CGSize(width: area.width * 1.35, height: area.height * 1.35)

        ZStack {
            diamond
                .fill(style.glow.opacity(0.28))
                .frame(width: glowSize.width, height: glowSize.height)
                .blur(radius: width * 0.018)
                .position(x: area.midX, y: area.midY)

            diamond
                .fill(
                    LinearGradient(
                        colors: [
                            style.frameDeep.opacity(0.92),
                            style.innerTint,
                            style.frameMid.opacity(0.55),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: area.width, height: area.height)
                .overlay {
                    diamond
                        .stroke(
                            LinearGradient(
                                colors: [style.accentBright, style.accent.opacity(0.65), style.frameDeep],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: max(1.5, width * 0.0025)
                        )
                }
                .position(x: area.midX, y: area.midY)

            Text(initials)
                .font(PlayerCardTypography.emblemInitials(size: area.width))
                .foregroundStyle(style.ratingForeground)
                .minimumScaleFactor(0.55)
                .lineLimit(1)
                .frame(width: area.width * 0.72)
                .position(x: area.midX, y: area.midY)
        }
        .allowsHitTesting(false)
    }
}
