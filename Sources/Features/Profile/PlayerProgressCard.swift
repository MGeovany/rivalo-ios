import SwiftUI
import UIKit

/// FUT player card matching the tier mockups — cutout portrait, ornate frame, INT/SPD/SPR/KM/MAT.
struct PlayerProgressCard: View {
    let model: PlayerCardModel
    var isPhotoAdjustable = false
    var onPhotoPlacementChange: ((PlayerCardPhotoPlacement) -> Void)?

    @State private var placement: PlayerCardPhotoPlacement = .default
    @State private var dragTranslation: CGSize = .zero
    @State private var livePinchScale: CGFloat = 1

    private var style: PlayerCardRankStyle { model.rank.style }

    var body: some View {
        ZStack {
            FUTCardShape()
                .fill(Color.black.opacity(0.4))
                .shadow(color: style.frameDeep.opacity(0.7), radius: 24, y: 14)
                .shadow(color: style.glow, radius: model.rank.isHolographic ? 28 : 10, y: 0)

            cardContent
                .clipShape(FUTCardShape())
                .padding(4)

            PlayerCardOrnateFrame(rank: model.rank, style: style)
                .padding(4)

            if model.rank.isHolographic {
                CardRankHolographicEffect()
                    .clipShape(FUTCardShape())
                    .padding(4)
            }
        }
        .aspectRatio(0.68, contentMode: .fit)
        .frame(maxWidth: 340)
        .frame(maxWidth: .infinity)
        .onAppear { placement = model.photoPlacement }
        .onChange(of: model.photoPlacement) { _, newValue in
            placement = newValue
            dragTranslation = .zero
            livePinchScale = 1
        }
    }

    private var cardContent: some View {
        ZStack {
            PlayerCardAmbientBackground(style: style)

            GeometryReader { geo in
                ZStack {
                    playerCutout(in: geo.size)

                    HStack(alignment: .bottom, spacing: 0) {
                        statColumn(left: true)
                            .padding(.leading, 14)
                        Spacer(minLength: geo.size.width * 0.28)
                        statColumn(left: false)
                            .padding(.trailing, 14)
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, geo.size.height * 0.21)

                    VStack {
                        topBand
                            .padding(.horizontal, 18)
                            .padding(.top, 16)
                        Spacer()
                    }

                    VStack(spacing: 4) {
                        Spacer()
                        PlayerCardNameCrest(style: style)
                        Text(model.displayName.uppercased())
                            .font(Theme.Typography.display(size: 22))
                            .foregroundStyle(style.ratingForeground)
                            .tracking(1.2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.55)
                            .shadow(color: style.glow, radius: 8, y: 0)
                            .padding(.horizontal, 12)
                        tierBar
                            .padding(.bottom, 10)
                    }
                }
            }
        }
    }

    // MARK: - Top band

    private var topBand: some View {
        HStack(alignment: .top) {
            ratingBlock
            Spacer()
            flagBlock
        }
    }

    private var ratingBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(model.displayStats.intValue)
                .font(Theme.Typography.display(size: 56))
                .foregroundStyle(style.ratingForeground)
                .tracking(-2)
                .shadow(color: .black.opacity(0.8), radius: 2, y: 2)
                .shadow(color: style.glow, radius: 8, y: 0)

            Text(model.positionAbbrev)
                .font(Theme.Typography.button(size: 16))
                .foregroundStyle(style.accentBright)
                .tracking(1.5)
                .shadow(color: .black.opacity(0.6), radius: 2, y: 1)
                .padding(.top, -6)
        }
    }

    private var flagBlock: some View {
        VStack(spacing: 3) {
            Text(FootballCountry.flagEmoji(for: model.countryCode))
                .font(.system(size: 26))
                .shadow(color: .black.opacity(0.5), radius: 3, y: 1)
            Text(model.countryCode.uppercased())
                .font(Theme.Typography.statLabel(size: 10))
                .foregroundStyle(style.accentBright.opacity(0.85))
                .tracking(0.8)
        }
        .accessibilityLabel(FootballCountry.name(for: model.countryCode))
    }

    // MARK: - Player cutout

    @ViewBuilder
    private func playerCutout(in size: CGSize) -> some View {
        let anchorX = size.width * (0.5 + placement.offsetX) + dragTranslation.width
        let anchorY = size.height * (0.58 + placement.offsetY) + dragTranslation.height
        let photoScale = placement.scale * livePinchScale

        ZStack {
            if let data = model.avatarImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        maxWidth: size.width * 0.94 * photoScale,
                        maxHeight: size.height * 0.72 * photoScale
                    )
                    .position(x: anchorX, y: anchorY)
                    .shadow(color: style.glow.opacity(0.6), radius: 16, y: 4)
                    .highPriorityGesture(photoAdjustGesture(in: size))
            } else {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [style.accent.opacity(0.2), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 140, height: 140)
                    Circle()
                        .stroke(style.borderGradient, lineWidth: 2)
                        .frame(width: 120, height: 120)
                    Text(model.initials)
                        .font(Theme.Typography.display(size: 48))
                        .foregroundStyle(style.accentBright)
                }
                .position(x: size.width * 0.5, y: size.height * 0.52)
            }

            if isPhotoAdjustable, model.avatarImageData != nil {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(style.accent.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                    .frame(width: size.width * 0.88, height: size.height * 0.52)
                    .position(x: size.width * 0.5, y: size.height * 0.48)
                    .allowsHitTesting(false)

                Text("Drag · Pinch to adjust")
                    .font(Theme.Typography.statLabel(size: 9))
                    .foregroundStyle(style.accentBright.opacity(0.75))
                    .tracking(0.6)
                    .position(x: size.width * 0.5, y: size.height * 0.74)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: size.width, height: size.height)
    }

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

    // MARK: - Stats

    private func statColumn(left: Bool) -> some View {
        VStack(alignment: left ? .leading : .trailing, spacing: 0) {
            if left {
                statBlock(abbrev: "INT", value: model.displayStats.intValue, alignment: .leading)
                statDivider
                statBlock(abbrev: "SPD", value: model.displayStats.spdValue, alignment: .leading)
            } else {
                statBlock(abbrev: "SPR", value: model.displayStats.sprValue, alignment: .trailing)
                statDivider
                statBlock(abbrev: "KM", value: model.displayStats.kmValue, alignment: .trailing)
                statDivider
                statBlock(abbrev: "MAT", value: model.displayStats.matValue, alignment: .trailing)
            }
        }
    }

    private func statBlock(abbrev: String, value: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 1) {
            Text(abbrev)
                .font(Theme.Typography.statLabel(size: 10))
                .foregroundStyle(style.accent.opacity(0.9))
            Text(value)
                .font(Theme.Typography.button(size: 18))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.85), radius: 2, y: 1)
        }
        .padding(.vertical, 4)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(style.accent.opacity(0.35))
            .frame(width: 52, height: 1)
            .padding(.vertical, 2)
    }

    // MARK: - Tier bar

    private var tierBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "diamond.fill")
                .font(.system(size: 5))
            Text(model.rank.displayName.uppercased())
                .font(Theme.Typography.statLabel(size: 9))
                .tracking(1.6)
            Image(systemName: "diamond.fill")
                .font(.system(size: 5))
        }
        .foregroundStyle(style.accentBright.opacity(0.9))
        .padding(.horizontal, 16)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.55))
                .overlay(Capsule().stroke(style.accent.opacity(0.25), lineWidth: 1))
        )
    }
}

// MARK: - Previews

private func previewModel(rank: PlayerCardRank, country: String = "CA") -> PlayerCardModel {
    PlayerCardModel(
        displayName: "Geovany",
        position: "Midfielder",
        positionAbbrev: "CM",
        matchCount: 5,
        rank: rank,
        tierProgress: 5,
        physicalRating: 74,
        displayStats: PlayerCardDisplayStats(
            intValue: "74",
            spdValue: "25.0",
            sprValue: "46",
            kmValue: "42.6",
            matValue: "5"
        ),
        countryCode: country,
        initials: "G",
        avatarImageData: nil,
        photoPlacement: .default
    )
}

#Preview("Bronze") {
    PlayerProgressCard(model: previewModel(rank: .bronze))
        .padding()
        .background(Color.black)
}

#Preview("Gold") {
    PlayerProgressCard(model: previewModel(rank: .gold))
        .padding()
        .background(Color.black)
}

#Preview("Holographic") {
    PlayerProgressCard(model: previewModel(rank: .holographic))
        .padding()
        .background(Color.black)
}
