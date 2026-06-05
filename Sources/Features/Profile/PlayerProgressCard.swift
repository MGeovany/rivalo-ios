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
            emblemOverlay
            layerImage(.frame)
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

    // MARK: - Emblem

    private var emblemOverlay: some View {
        let area = PlayerCardLayout.emblem.frame(in: canvasSize)
        let diameter = min(area.width, area.height)
        let center = PlayerCardLayout.emblem.center(in: canvasSize)

        return ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [style.glow.opacity(0.55), style.innerTint.opacity(0.95), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: diameter * 0.62
                    )
                )
                .frame(width: diameter * 1.18, height: diameter * 1.18)
                .position(center)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [style.frameTop.opacity(0.35), style.innerTint, style.frameDeep.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: diameter, height: diameter)
                .overlay {
                    Circle()
                        .strokeBorder(style.borderGradient, lineWidth: max(2, width * 0.004))
                }
                .shadow(color: style.glow.opacity(0.45), radius: diameter * 0.08)
                .position(center)

            Image(systemName: "rosette")
                .font(.system(size: diameter * 0.92, weight: .bold))
                .foregroundStyle(style.accent.opacity(0.22))
                .position(center)

            Text(content.initials)
                .font(PlayerCardTypography.emblemInitials(size: width))
                .foregroundStyle(style.ratingForeground)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .frame(width: diameter * 0.62)
                .position(center)

            if let badge = content.achievementBadge {
                Text(badge.label)
                    .font(PlayerCardTypography.emblemBadge(size: width))
                    .foregroundStyle(style.accentBright)
                    .padding(.horizontal, width * 0.018)
                    .padding(.vertical, height * 0.004)
                    .background(style.frameDeep.opacity(0.82))
                    .clipShape(Capsule())
                    .overlay {
                        Capsule()
                            .strokeBorder(style.accent.opacity(0.55), lineWidth: max(1, width * 0.0015))
                    }
                    .position(
                        x: center.x,
                        y: center.y + diameter * 0.44
                    )
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
        let leftArea = PlayerCardLayout.leftStats
        let rightArea = PlayerCardLayout.rightStats
        let bandTop = rightArea.y
        let bandHeight = PlayerCardLayout.playerName.y - bandTop - 0.025
        let rowWidth = rightArea.x + rightArea.width - leftArea.x
        let columnWidth = width * leftArea.width
        let dividerPadding = height * 0.008
        let valueFont = statsValueFont

        return HStack(alignment: .bottom, spacing: 0) {
            statsColumn(
                left: true,
                columnWidth: columnWidth,
                dividerPadding: dividerPadding,
                valueFont: valueFont,
                entries: [
                    (.intensity, content.intensityText),
                    (.speed, content.topSpeedText),
                ]
            )
            Spacer(minLength: width * 0.06)
            statsColumn(
                left: false,
                columnWidth: columnWidth,
                dividerPadding: dividerPadding,
                valueFont: valueFont,
                entries: [
                    (.sprints, content.sprintsText),
                    (.distance, content.distanceText),
                    (.matches, content.matchesText),
                ]
            )
        }
        .frame(width: width * rowWidth, height: height * bandHeight, alignment: .bottom)
        .position(
            x: width * (leftArea.x + rowWidth / 2),
            y: height * (bandTop + bandHeight / 2)
        )
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
            .accessibilityHint("Shows what this stat means")
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

// MARK: - Previews

private func previewContent(tier: PlayerCardRank, country: String = "CA") -> PlayerCardContent {
    PlayerCardContent(
        name: "Geovany",
        initials: "G",
        countryCode: country,
        position: "Midfielder",
        rating: 74,
        tier: tier,
        matches: 5,
        distanceKm: 42.6,
        topSpeed: 25.0,
        sprints: 46,
        intensity: 74,
        achievementBadge: .newPR
    )
}

#Preview("Bronze card") {
    PlayerProgressCard(content: previewContent(tier: .bronze))
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
