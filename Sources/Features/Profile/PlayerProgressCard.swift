import SwiftUI
import UIKit

/// Stateless card renderer at an explicit canvas size (display + export).
struct PlayerProgressCardCanvas: View {
    let content: PlayerCardContent
    let canvasSize: CGSize
    let images: [PlayerCardLayer: UIImage]
    var showsStatExplanations = false

    @State private var explainedStat: PlayerCardStatKind?

    private var style: PlayerCardRankStyle { content.tier.style }
    private var width: CGFloat { canvasSize.width }
    private var height: CGFloat { canvasSize.height }

    var body: some View {
        ZStack {
            layerImage(.background)
            layerImage(.frame)
            PlayerCardEmblem(
                initials: content.initials,
                style: style,
                canvasSize: canvasSize
            )
            ratingOverlay
            positionOverlay
            flagOverlay
            statsOverlay
            nameOverlay
            layerImage(.fxOverlay)
        }
        .frame(width: width, height: height)
        .clipped()
        .alert(item: $explainedStat) { stat in
            Alert(
                title: Text(stat.title),
                message: Text(stat.explanation),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // MARK: - Layers

    private func layerImage(_ layer: PlayerCardLayer) -> some View {
        Group {
            if let uiImage = images[layer] {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
            } else {
                Color.clear
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Overlays

    private var ratingOverlay: some View {
        let area = PlayerCardLayout.rating

        return Text(content.ratingText)
            .font(PlayerCardTypography.rating(size: width))
            .foregroundStyle(style.ratingForeground)
            .tracking(-4)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(width: width * area.width, height: width * area.height * 0.92, alignment: .topLeading)
            .position(
                x: width * (area.x + area.width / 2),
                y: height * (area.y + area.height * 0.40)
            )
    }

    private var positionOverlay: some View {
        let area = PlayerCardLayout.position

        return Text(content.positionAbbrev)
            .font(PlayerCardTypography.position(size: width))
            .foregroundStyle(style.accentBright)
            .tracking(1.6)
            .frame(width: width * area.width, alignment: .leading)
            .position(
                x: width * (area.x + area.width / 2),
                y: height * (area.y + area.height / 2 + 0.008)
            )
    }

    private var flagOverlay: some View {
        let area = PlayerCardLayout.country

        return VStack(spacing: height * 0.006) {
            Text(FootballCountry.flagEmoji(for: content.countryCode))
                .font(.system(size: width * 0.092))
            Text(content.countryCode.uppercased())
                .font(PlayerCardTypography.countryCode(size: width))
                .foregroundStyle(style.accentBright.opacity(0.92))
                .tracking(1.2)
        }
        .position(
            x: width * (area.x + area.width / 2),
            y: height * (area.y + area.height / 2)
        )
        .accessibilityLabel(FootballCountry.name(for: content.countryCode))
    }

    private var statsOverlay: some View {
        let valueFont = statsValueFont
        let dividerPadding = height * 0.008

        return ZStack {
            positionedStatsColumn(
                area: PlayerCardLayout.leftStats,
                left: true,
                dividerPadding: dividerPadding,
                valueFont: valueFont,
                entries: [
                    (.intensity, content.intensityText),
                    (.speed, content.topSpeedText),
                ]
            )
            positionedStatsColumn(
                area: PlayerCardLayout.rightStats,
                left: false,
                dividerPadding: dividerPadding,
                valueFont: valueFont,
                entries: [
                    (.sprints, content.sprintsText),
                    (.distance, content.distanceText),
                    (.matches, content.matchesText),
                ]
            )
        }
    }

    private func positionedStatsColumn(
        area: PlayerCardLayout.SafeArea,
        left: Bool,
        dividerPadding: CGFloat,
        valueFont: Font,
        entries: [(PlayerCardStatKind, String)]
    ) -> some View {
        let frame = area.frame(in: canvasSize)

        return statsColumn(
            left: left,
            columnWidth: frame.width,
            dividerPadding: dividerPadding,
            valueFont: valueFont,
            entries: entries
        )
        .frame(width: frame.width, height: frame.height, alignment: left ? .bottomLeading : .bottomTrailing)
        .position(x: frame.midX, y: frame.midY)
    }

    /// One value size for both columns — sized to the longest stat so nothing scales unevenly.
    private var statsValueFont: Font {
        let values = [
            content.intensityText,
            content.topSpeedText,
            content.sprintsText,
            content.distanceText,
            content.matchesText,
        ]
        return PlayerCardTypography.statValue(size: width, longestValueLength: values.map(\.count).max() ?? 1)
    }

    private func statsColumn(
        left: Bool,
        columnWidth: CGFloat,
        dividerPadding: CGFloat,
        valueFont: Font,
        entries: [(PlayerCardStatKind, String)]
    ) -> some View {
        VStack(alignment: left ? .leading : .trailing, spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
                if index > 0 {
                    Rectangle()
                        .fill(style.accent.opacity(0.45))
                        .frame(width: columnWidth * 0.9, height: max(1, width * 0.001))
                        .padding(.vertical, dividerPadding)
                }
                statBlock(
                    kind: entry.0,
                    value: entry.1,
                    left: left,
                    columnWidth: columnWidth,
                    valueFont: valueFont
                )
            }
        }
        .frame(width: columnWidth, alignment: left ? .leading : .trailing)
    }

    @ViewBuilder
    private func statBlock(
        kind: PlayerCardStatKind,
        value: String,
        left: Bool,
        columnWidth: CGFloat,
        valueFont: Font
    ) -> some View {
        let alignment: Alignment = left ? .leading : .trailing
        let block = VStack(alignment: left ? .leading : .trailing, spacing: height * 0.004) {
            Text(kind.abbrev)
                .font(PlayerCardTypography.statLabel(size: width))
                .foregroundStyle(style.accent.opacity(0.95))
                .lineLimit(1)
                .frame(maxWidth: columnWidth, alignment: alignment)
            Text(value)
                .font(valueFont)
                .foregroundStyle(.white)
                .monospacedDigit()
                .lineLimit(1)
                .frame(maxWidth: columnWidth, alignment: alignment)
        }
        .accessibilityLabel("\(kind.title), \(value)")

        if showsStatExplanations {
            Button {
                explainedStat = kind
            } label: {
                block
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Muestra lo que significa esta estadística")
        } else {
            block
        }
    }

    private var nameOverlay: some View {
        let area = PlayerCardLayout.playerName

        return Text(content.name.uppercased())
            .font(PlayerCardTypography.playerName(size: width))
            .foregroundStyle(style.ratingForeground)
            .tracking(2)
            .lineLimit(1)
            .minimumScaleFactor(0.55)
            .frame(width: width * area.width)
            .position(
                x: width * (area.x + area.width / 2),
                y: height * (area.y + area.height / 2)
            )
    }
}

/// Composes layered tier assets with a player insignia and live stat overlays.
struct PlayerProgressCard: View {
    let content: PlayerCardContent

    @State private var assetLoader = PlayerCardAssetLoader()
    @State private var sheenPhase: CGFloat = -0.5

    init(content: PlayerCardContent) {
        self.content = content
    }

    init(model: PlayerCardModel) {
        self.init(content: model.content)
    }

    var body: some View {
        GeometryReader { geo in
            PlayerProgressCardCanvas(
                content: content,
                canvasSize: geo.size,
                images: assetLoader.images,
                showsStatExplanations: true
            )
            .overlay { sheen(size: geo.size) }
        }
        .aspectRatio(PlayerCardLayout.aspectRatio, contentMode: .fit)
        .frame(maxWidth: 340)
        .frame(maxWidth: .infinity)
        .overlay {
            if assetLoader.isLoading, assetLoader.images.isEmpty {
                ProgressView()
                    .tint(content.tier.style.accentBright)
            }
        }
        .task(id: content.tier) {
            await assetLoader.load(tier: content.tier)
            sheenPhase = -0.5
            withAnimation(.easeInOut(duration: 1.2).delay(0.3)) {
                sheenPhase = 1.5
            }
        }
    }

    /// One-shot light sweep across the card after the tier assets load.
    @ViewBuilder
    private func sheen(size: CGSize) -> some View {
        if !assetLoader.images.isEmpty {
            LinearGradient(
                colors: [.clear, Color.white.opacity(0.14), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: size.width * 0.5, height: size.height * 1.4)
            .rotationEffect(.degrees(18))
            .offset(x: size.width * (sheenPhase * 1.6 - 0.8))
            .mask {
                RoundedRectangle(cornerRadius: size.width * 0.06)
                    .frame(width: size.width, height: size.height)
            }
            .allowsHitTesting(false)
        }
    }

    @MainActor
    func exportImage(scale: CGFloat = 2) async -> UIImage? {
        await assetLoader.load(tier: content.tier)
        return PlayerCardExporter.renderImage(
            content: content,
            images: assetLoader.images,
            scale: scale
        )
    }

    @MainActor
    func exportPNGData(scale: CGFloat = 2) async -> Data? {
        await exportImage(scale: scale)?.pngData()
    }
}

// MARK: - Emblem

private struct PlayerCardDiamondShape: Shape {
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

private struct PlayerCardEmblem: View {
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

// MARK: - Previews

private func previewContent(tier: PlayerCardRank, country: String = "HN") -> PlayerCardContent {
    PlayerCardContent(
        name: "Alex",
        initials: "A",
        countryCode: country,
        position: "Forward",
        rating: 74,
        tier: tier,
        matches: 20,
        distanceKm: 145.8,
        topSpeed: 28.5,
        sprints: 174,
        intensity: 74
    )
}

#Preview("Bronze card") {
    PlayerProgressCard(content: previewContent(tier: .bronze))
        .padding()
        .background(Color.black)
}

#Preview("Platinum card") {
    PlayerProgressCard(content: previewContent(tier: .platinum))
        .padding()
        .background(Color.black)
}

#Preview("Gold card") {
    PlayerProgressCard(content: previewContent(tier: .gold))
        .padding()
        .background(Color.black)
}

#Preview("Holographic card") {
    PlayerProgressCard(content: previewContent(tier: .holographic))
        .padding()
        .background(Color.black)
}
