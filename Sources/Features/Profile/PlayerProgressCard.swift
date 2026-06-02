import SwiftUI
import UIKit

/// Stateless card renderer at an explicit canvas size (display + export).
struct PlayerProgressCardCanvas: View {
    let content: PlayerCardContent
    let canvasSize: CGSize
    let images: [PlayerCardLayer: UIImage]
    var avatarImageData: Data?
    var isPendingPhotoPlacement = false
    var photoPlacement: PlayerCardPhotoPlacement = .default
    var isPhotoAdjustable = false
    var onPhotoPlacementChange: ((PlayerCardPhotoPlacement) -> Void)?

    @State private var placement: PlayerCardPhotoPlacement = .default
    @State private var dragTranslation: CGSize = .zero
    @State private var livePinchScale: CGFloat = 1

    private var style: PlayerCardRankStyle { content.tier.style }
    private var width: CGFloat { canvasSize.width }
    private var height: CGFloat { canvasSize.height }

    var body: some View {
        ZStack {
            layerImage(.background)
            if avatarImageData != nil {
                playerPhoto
            }
            layerImage(.frame)
            ratingOverlay
            positionOverlay
            flagOverlay
            statsOverlay
            nameOverlay
            layerImage(.fxOverlay)
            if isPhotoAdjustable, avatarImageData != nil {
                photoAdjustHint
            }
        }
        .frame(width: width, height: height)
        .clipped()
        .onAppear { placement = photoPlacement }
        .onChange(of: photoPlacement) { _, newValue in
            placement = newValue
            dragTranslation = .zero
            livePinchScale = 1
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

    // MARK: - Player photo

    @ViewBuilder
    private var playerPhoto: some View {
        if let data = avatarImageData, let uiImage = UIImage(data: data) {
            let anchor = portraitCenter
            let portrait = PlayerCardLayout.portrait.frame(in: canvasSize)
            let photoScale = placement.scale * livePinchScale

            ZStack {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: portrait.width * photoScale, height: portrait.height * photoScale)
                    .position(x: anchor.x, y: anchor.y)
            }
            .frame(width: width, height: height)
            .modifier(PhotoMaskModifier(isPending: isPendingPhotoPlacement, mask: softPhotoMask))
            .modifier(ConditionalGestureModifier(isEnabled: isPhotoAdjustable, gesture: photoAdjustGesture))
        }
    }

    private struct PhotoMaskModifier: ViewModifier {
        let isPending: Bool
        let mask: AnyView

        init(isPending: Bool, mask: some View) {
            self.isPending = isPending
            self.mask = AnyView(mask)
        }

        func body(content: Content) -> some View {
            if isPending {
                content
            } else {
                content.mask(mask)
            }
        }
    }

    private struct ConditionalGestureModifier<G: Gesture>: ViewModifier {
        let isEnabled: Bool
        let gesture: G

        func body(content: Content) -> some View {
            if isEnabled {
                content.highPriorityGesture(gesture)
            } else {
                content
            }
        }
    }

    private var portraitCenter: CGPoint {
        let portrait = PlayerCardLayout.portrait
        return CGPoint(
            x: width * (portrait.x + portrait.width / 2 + placement.offsetX) + dragTranslation.width,
            y: height * (portrait.y + portrait.height / 2 + placement.offsetY) + dragTranslation.height
        )
    }

    private var softPhotoMask: some View {
        Group {
            if let uiImage = images[.photoMask] {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
            } else {
                LinearGradient(
                    colors: [.white, .white.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    private var photoAdjustHint: some View {
        let portrait = PlayerCardLayout.portrait.frame(in: canvasSize)

        return ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(style.accent.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                .frame(width: portrait.width, height: portrait.height)
                .position(x: portrait.midX, y: portrait.midY)

            Text(isPendingPhotoPlacement ? "Drag · Pinch to position" : "Drag · Pinch to adjust")
                .font(PlayerCardTypography.statLabel(size: width))
                .foregroundStyle(style.accentBright.opacity(0.8))
                .position(x: width * 0.5, y: portrait.maxY + height * 0.02)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Overlays

    private var ratingOverlay: some View {
        let area = PlayerCardLayout.rating

        return Text(content.ratingText)
            .font(PlayerCardTypography.rating(size: width))
            .foregroundStyle(style.ratingForeground)
            .tracking(-2)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(width: width * area.width, height: width * area.height * 0.72, alignment: .topLeading)
            .position(
                x: width * (area.x + area.width / 2),
                y: height * (area.y + area.height * 0.36)
            )
    }

    private var positionOverlay: some View {
        let area = PlayerCardLayout.position

        return Text(content.positionAbbrev)
            .font(PlayerCardTypography.position(size: width))
            .foregroundStyle(style.accentBright)
            .tracking(1.4)
            .frame(width: width * area.width, alignment: .leading)
            .position(
                x: width * (area.x + area.width / 2),
                y: height * (area.y + area.height / 2)
            )
    }

    private var flagOverlay: some View {
        let area = PlayerCardLayout.country

        return VStack(spacing: height * 0.004) {
            Text(FootballCountry.flagEmoji(for: content.countryCode))
                .font(.system(size: width * 0.065))
            Text(content.countryCode.uppercased())
                .font(PlayerCardTypography.countryCode(size: width))
                .foregroundStyle(style.accentBright.opacity(0.92))
                .tracking(1)
        }
        .position(
            x: width * (area.x + area.width / 2),
            y: height * (area.y + area.height / 2)
        )
        .accessibilityLabel(FootballCountry.name(for: content.countryCode))
    }

    private var statsOverlay: some View {
        ZStack {
            statColumn(
                left: true,
                area: PlayerCardLayout.leftStats,
                entries: [
                    ("INT", content.intensityText),
                    ("SPD", content.topSpeedText),
                ]
            )
            statColumn(
                left: false,
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
        area: PlayerCardLayout.SafeArea,
        entries: [(String, String)]
    ) -> some View {
        VStack(alignment: left ? .leading : .trailing, spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
                if index > 0 {
                    Rectangle()
                        .fill(style.accent.opacity(0.45))
                        .frame(width: width * area.width * 0.9, height: max(1, width * 0.001))
                        .padding(.vertical, height * 0.010)
                }
                statBlock(abbrev: entry.0, value: entry.1, left: left, columnWidth: width * area.width)
            }
        }
        .frame(width: width * area.width, alignment: left ? .leading : .trailing)
        .position(
            x: width * (area.x + area.width / 2),
            y: height * (area.y + area.height / 2)
        )
    }

    private func statBlock(abbrev: String, value: String, left: Bool, columnWidth: CGFloat) -> some View {
        let alignment: Alignment = left ? .leading : .trailing

        return VStack(alignment: left ? .leading : .trailing, spacing: height * 0.002) {
            Text(abbrev)
                .font(PlayerCardTypography.statLabel(size: width))
                .foregroundStyle(style.accent.opacity(0.95))
                .lineLimit(1)
                .frame(maxWidth: columnWidth, alignment: alignment)
            Text(value)
                .font(PlayerCardTypography.statValue(size: width))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .frame(maxWidth: columnWidth, alignment: alignment)
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

    // MARK: - Gestures

    private var photoAdjustGesture: some Gesture {
        let drag = DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard isPhotoAdjustable else { return }
                dragTranslation = value.translation
            }
            .onEnded { value in
                guard isPhotoAdjustable else { return }
                commitDrag(value.translation)
            }

        let pinch = MagnificationGesture()
            .onChanged { value in
                guard isPhotoAdjustable else { return }
                livePinchScale = value
            }
            .onEnded { value in
                guard isPhotoAdjustable else { return }
                commitPinch(value)
            }

        return SimultaneousGesture(drag, pinch)
    }

    private func commitDrag(_ translation: CGSize) {
        var updated = placement
        updated.offsetX += translation.width / width
        updated.offsetY += translation.height / height
        updated = updated.clamped()
        placement = updated
        dragTranslation = .zero
        onPhotoPlacementChange?(updated)
    }

    private func commitPinch(_ multiplier: CGFloat) {
        var updated = placement
        updated.scale *= multiplier
        updated = updated.clamped()
        placement = updated
        livePinchScale = 1
        onPhotoPlacementChange?(updated)
    }
}

/// Composes layered tier assets with a user cutout and live stat overlays.
struct PlayerProgressCard: View {
    let content: PlayerCardContent
    var avatarImageData: Data?
    var isPendingPhotoPlacement = false
    var photoPlacement: PlayerCardPhotoPlacement = .default
    var isPhotoAdjustable = false
    var onPhotoPlacementChange: ((PlayerCardPhotoPlacement) -> Void)?

    @State private var assetLoader = PlayerCardAssetLoader()

    init(
        content: PlayerCardContent,
        avatarImageData: Data? = nil,
        isPendingPhotoPlacement: Bool = false,
        photoPlacement: PlayerCardPhotoPlacement = .default,
        isPhotoAdjustable: Bool = false,
        onPhotoPlacementChange: ((PlayerCardPhotoPlacement) -> Void)? = nil
    ) {
        self.content = content
        self.avatarImageData = avatarImageData
        self.isPendingPhotoPlacement = isPendingPhotoPlacement
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
            isPendingPhotoPlacement: model.isPendingPhotoPlacement,
            photoPlacement: model.photoPlacement,
            isPhotoAdjustable: isPhotoAdjustable,
            onPhotoPlacementChange: onPhotoPlacementChange
        )
    }

    var body: some View {
        GeometryReader { geo in
            PlayerProgressCardCanvas(
                content: content,
                canvasSize: geo.size,
                images: assetLoader.images,
                avatarImageData: avatarImageData,
                isPendingPhotoPlacement: isPendingPhotoPlacement,
                photoPlacement: photoPlacement,
                isPhotoAdjustable: isPhotoAdjustable,
                onPhotoPlacementChange: onPhotoPlacementChange
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
            avatarImageData: avatarImageData,
            photoPlacement: photoPlacement,
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
