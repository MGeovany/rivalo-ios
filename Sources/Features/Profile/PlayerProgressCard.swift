import SwiftUI
import UIKit

/// Composes layered tier assets with a user cutout and live stat overlays.
struct PlayerProgressCard: View {
    let content: PlayerCardContent
    var avatarImageData: Data?
    var photoPlacement: PlayerCardPhotoPlacement = .default
    var isPhotoAdjustable = false
    var onPhotoPlacementChange: ((PlayerCardPhotoPlacement) -> Void)?

    @State private var placement: PlayerCardPhotoPlacement = .default
    @State private var dragTranslation: CGSize = .zero
    @State private var livePinchScale: CGFloat = 1
    @State private var assetLoader = PlayerCardAssetLoader()

    private var style: PlayerCardRankStyle { content.tier.style }

    init(
        content: PlayerCardContent,
        avatarImageData: Data? = nil,
        photoPlacement: PlayerCardPhotoPlacement = .default,
        isPhotoAdjustable: Bool = false,
        onPhotoPlacementChange: ((PlayerCardPhotoPlacement) -> Void)? = nil
    ) {
        self.content = content
        self.avatarImageData = avatarImageData
        self.photoPlacement = photoPlacement
        self.isPhotoAdjustable = isPhotoAdjustable
        self.onPhotoPlacementChange = onPhotoPlacementChange
    }

    init(
        model: PlayerCardModel,
        isPhotoAdjustable: Bool = false,
        onPhotoPlacementChange: ((PlayerCardPhotoPlacement) -> Void)? = nil
    ) {
        self.init(
            content: model.content,
            avatarImageData: model.avatarImageData,
            photoPlacement: model.photoPlacement,
            isPhotoAdjustable: isPhotoAdjustable,
            onPhotoPlacementChange: onPhotoPlacementChange
        )
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                layerImage(.background, size: size)

                if avatarImageData != nil {
                    playerPhoto(in: size)
                }

                layerImage(.frame, size: size)
                ratingOverlay(in: size)
                flagOverlay(in: size)
                statsOverlay(in: size)
                nameOverlay(in: size)
                tierLabelOverlay(in: size)

                layerImage(.fxOverlay, size: size)

                if isPhotoAdjustable, avatarImageData != nil {
                    photoAdjustHint(in: size)
                }
            }
        }
        .aspectRatio(PlayerCardLayout.aspectRatio, contentMode: .fit)
        .frame(maxWidth: 340)
        .frame(maxWidth: .infinity)
        .onAppear { placement = photoPlacement }
        .task(id: content.tier) {
            await assetLoader.load(tier: content.tier)
        }
        .onChange(of: photoPlacement) { _, newValue in
            placement = newValue
            dragTranslation = .zero
            livePinchScale = 1
        }
    }

    // MARK: - Layers

    private func layerImage(_ layer: PlayerCardLayer, size: CGSize) -> some View {
        Group {
            if let uiImage = assetLoader.image(for: layer) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipped()
            } else {
                cardPlaceholder(in: size)
            }
        }
        .allowsHitTesting(false)
    }

    private func cardPlaceholder(in size: CGSize) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(style.innerTint)
            .overlay {
                if assetLoader.isLoading {
                    ProgressView()
                        .tint(style.accentBright)
                }
            }
            .frame(width: size.width, height: size.height)
    }

    // MARK: - Player photo

    @ViewBuilder
    private func playerPhoto(in size: CGSize) -> some View {
        if let data = avatarImageData, let uiImage = UIImage(data: data) {
            let anchor = portraitCenter(in: size)
            let portrait = PlayerCardLayout.portrait.frame(in: size)
            let photoScale = placement.scale * livePinchScale
            let photoWidth = portrait.width * photoScale
            let photoHeight = portrait.height * photoScale

            ZStack {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: photoWidth, height: photoHeight)
                    .position(x: anchor.x, y: anchor.y)
            }
            .frame(width: size.width, height: size.height)
            .mask(softPhotoMask(in: size))
            .highPriorityGesture(photoAdjustGesture(in: size))
        }
    }

    private func portraitCenter(in size: CGSize) -> CGPoint {
        let portrait = PlayerCardLayout.portrait
        return CGPoint(
            x: size.width * (portrait.x + portrait.width / 2 + placement.offsetX) + dragTranslation.width,
            y: size.height * (portrait.y + portrait.height / 2 + placement.offsetY) + dragTranslation.height
        )
    }

    private func softPhotoMask(in size: CGSize) -> some View {
        Group {
            if let uiImage = assetLoader.image(for: .photoMask) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
            } else {
                LinearGradient(
                    colors: [.white, .white.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    private func photoAdjustHint(in size: CGSize) -> some View {
        let portrait = PlayerCardLayout.portrait.frame(in: size)

        return ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(style.accent.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                .frame(width: portrait.width, height: portrait.height)
                .position(x: portrait.midX, y: portrait.midY)

            Text("Drag · Pinch to adjust")
                .font(Theme.Typography.statLabel(size: 9))
                .foregroundStyle(style.accentBright.opacity(0.8))
                .position(x: size.width * 0.5, y: portrait.maxY + size.height * 0.02)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Overlays

    private func ratingOverlay(in size: CGSize) -> some View {
        let area = PlayerCardLayout.rating

        return VStack(alignment: .leading, spacing: 0) {
            Text(content.ratingText)
                .font(Theme.Typography.display(size: size.width * 0.15))
                .foregroundStyle(style.ratingForeground)
                .tracking(-1)
                .shadow(color: .black.opacity(0.85), radius: 2, y: 2)
                .shadow(color: style.glow, radius: 6, y: 0)

            Text(content.positionAbbrev)
                .font(Theme.Typography.button(size: size.width * 0.045))
                .foregroundStyle(style.accentBright)
                .tracking(1.2)
                .shadow(color: .black.opacity(0.7), radius: 2, y: 1)
                .padding(.top, -2)
        }
        .frame(width: size.width * area.width, alignment: .leading)
        .position(area.center(in: size))
    }

    private func flagOverlay(in size: CGSize) -> some View {
        VStack(spacing: size.height * 0.006) {
            Text(FootballCountry.flagEmoji(for: content.countryCode))
                .font(.system(size: size.width * 0.07))
            Text(content.countryCode.uppercased())
                .font(Theme.Typography.statLabel(size: size.width * 0.028))
                .foregroundStyle(style.accentBright.opacity(0.9))
                .tracking(0.8)
        }
        .shadow(color: .black.opacity(0.6), radius: 3, y: 1)
        .position(PlayerCardLayout.country.center(in: size))
        .accessibilityLabel(FootballCountry.name(for: content.countryCode))
    }

    private func statsOverlay(in size: CGSize) -> some View {
        ZStack {
            statColumn(
                left: true,
                size: size,
                area: PlayerCardLayout.leftStats,
                entries: [
                    ("INT", content.intensityText),
                    ("SPD", content.topSpeedText),
                ]
            )

            statColumn(
                left: false,
                size: size,
                area: PlayerCardLayout.rightStats,
                entries: [
                    ("SPR", content.sprintsText),
                    ("KM", content.distanceText),
                    ("MAT", content.matchesText),
                ]
            )
        }
    }

    private func statColumn(
        left: Bool,
        size: CGSize,
        area: PlayerCardLayout.SafeArea,
        entries: [(String, String)]
    ) -> some View {
        VStack(alignment: left ? .leading : .trailing, spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
                if index > 0 {
                    Rectangle()
                        .fill(style.accent.opacity(0.35))
                        .frame(width: size.width * area.width * 0.85, height: 1)
                        .padding(.vertical, size.height * 0.012)
                }
                statBlock(abbrev: entry.0, value: entry.1, size: size, left: left)
            }
        }
        .frame(width: size.width * area.width)
        .position(area.center(in: size))
    }

    private func statBlock(abbrev: String, value: String, size: CGSize, left: Bool) -> some View {
        VStack(alignment: left ? .leading : .trailing, spacing: 1) {
            Text(abbrev)
                .font(Theme.Typography.statLabel(size: size.width * 0.028))
                .foregroundStyle(style.accent.opacity(0.95))
            Text(value)
                .font(Theme.Typography.button(size: size.width * 0.048))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.9), radius: 2, y: 1)
        }
    }

    private func nameOverlay(in size: CGSize) -> some View {
        Text(content.name.uppercased())
            .font(Theme.Typography.display(size: size.width * 0.062))
            .foregroundStyle(style.ratingForeground)
            .tracking(1)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(maxWidth: size.width * PlayerCardLayout.playerName.width)
            .shadow(color: .black.opacity(0.8), radius: 2, y: 2)
            .shadow(color: style.glow, radius: 6, y: 0)
            .position(PlayerCardLayout.playerName.center(in: size))
    }

    private func tierLabelOverlay(in size: CGSize) -> some View {
        Text(content.tierLabel)
            .font(Theme.Typography.statLabel(size: size.width * 0.028))
            .foregroundStyle(style.accentBright)
            .tracking(1.4)
            .shadow(color: .black.opacity(0.75), radius: 2, y: 1)
            .position(PlayerCardLayout.tierLabel.center(in: size))
    }

    // MARK: - Gestures

    private func photoAdjustGesture(in size: CGSize) -> some Gesture {
        let drag = DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard isPhotoAdjustable else { return }
                dragTranslation = value.translation
            }
            .onEnded { value in
                guard isPhotoAdjustable else { return }
                commitDrag(value.translation, cardSize: size)
            }

        let pinch = MagnificationGesture()
            .onChanged { value in
                guard isPhotoAdjustable else { return }
                livePinchScale = value
            }
            .onEnded { value in
                guard isPhotoAdjustable else { return }
                commitPinch(value, cardSize: size)
            }

        return SimultaneousGesture(drag, pinch)
    }

    private func commitDrag(_ translation: CGSize, cardSize: CGSize) {
        var updated = placement
        updated.offsetX += translation.width / cardSize.width
        updated.offsetY += translation.height / cardSize.height
        updated = updated.clamped()
        placement = updated
        dragTranslation = .zero
        onPhotoPlacementChange?(updated)
    }

    private func commitPinch(_ multiplier: CGFloat, cardSize: CGSize) {
        _ = cardSize
        var updated = placement
        updated.scale *= multiplier
        updated = updated.clamped()
        placement = updated
        livePinchScale = 1
        onPhotoPlacementChange?(updated)
    }
}

// MARK: - Previews

private func previewContent(tier: PlayerCardRank, country: String = "CA") -> PlayerCardContent {
    PlayerCardContent(
        name: "Geovany",
        countryCode: country,
        position: "Midfielder",
        rating: 74,
        tier: tier,
        matches: 5,
        distanceKm: 42.6,
        topSpeed: 25.0,
        sprints: 46,
        intensity: 74
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
