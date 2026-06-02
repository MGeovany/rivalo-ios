import SwiftUI
import UIKit

/// Composes rank template assets with a user cutout and live stat overlays.
struct PlayerProgressCard: View {
    let model: PlayerCardModel
    var isPhotoAdjustable = false
    var onPhotoPlacementChange: ((PlayerCardPhotoPlacement) -> Void)?

    @State private var placement: PlayerCardPhotoPlacement = .default
    @State private var dragTranslation: CGSize = .zero
    @State private var livePinchScale: CGFloat = 1

    private var style: PlayerCardRankStyle { model.rank.style }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                Image(PlayerCardTemplate.assetName(for: model.rank))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipped()

                if model.avatarImageData != nil {
                    playerPhoto(in: size)
                }

                ratingOverlay(in: size)
                flagOverlay(in: size)
                statsOverlay(in: size)
                nameOverlay(in: size)

                if model.rank == .unranked {
                    tierLabelOverlay(in: size, text: "UNRANKED")
                }

                if isPhotoAdjustable, model.avatarImageData != nil {
                    photoAdjustHint(in: size)
                }
            }
        }
        .aspectRatio(PlayerCardLayout.aspectRatio, contentMode: .fit)
        .frame(maxWidth: 340)
        .frame(maxWidth: .infinity)
        .onAppear { placement = model.photoPlacement }
        .onChange(of: model.photoPlacement) { _, newValue in
            placement = newValue
            dragTranslation = .zero
            livePinchScale = 1
        }
    }

    // MARK: - Player photo

    @ViewBuilder
    private func playerPhoto(in size: CGSize) -> some View {
        if let data = model.avatarImageData, let uiImage = UIImage(data: data) {
            let anchorX = size.width * (PlayerCardLayout.photoAnchorX + placement.offsetX) + dragTranslation.width
            let anchorY = size.height * (PlayerCardLayout.photoAnchorY + placement.offsetY) + dragTranslation.height
            let photoScale = placement.scale * livePinchScale

            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(
                    maxWidth: size.width * PlayerCardLayout.photoMaxWidth * photoScale,
                    maxHeight: size.height * PlayerCardLayout.photoMaxHeight * photoScale
                )
                .position(x: anchorX, y: anchorY)
                .highPriorityGesture(photoAdjustGesture(in: size))
        }
    }

    private func photoAdjustHint(in size: CGSize) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(style.accent.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                .frame(width: size.width * 0.72, height: size.height * 0.48)
                .position(
                    x: size.width * PlayerCardLayout.photoAnchorX,
                    y: size.height * PlayerCardLayout.photoAnchorY
                )

            Text("Drag · Pinch to adjust")
                .font(Theme.Typography.statLabel(size: 9))
                .foregroundStyle(style.accentBright.opacity(0.8))
                .position(x: size.width * 0.5, y: size.height * 0.64)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Overlays

    private func ratingOverlay(in size: CGSize) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(model.displayStats.intValue)
                .font(Theme.Typography.display(size: size.width * 0.15))
                .foregroundStyle(style.ratingForeground)
                .tracking(-1)
                .shadow(color: .black.opacity(0.85), radius: 2, y: 2)
                .shadow(color: style.glow, radius: 6, y: 0)

            Text(model.positionAbbrev)
                .font(Theme.Typography.button(size: size.width * 0.045))
                .foregroundStyle(style.accentBright)
                .tracking(1.2)
                .shadow(color: .black.opacity(0.7), radius: 2, y: 1)
                .padding(.top, -2)
        }
        .position(x: size.width * PlayerCardLayout.ratingX, y: size.height * PlayerCardLayout.ratingY)
    }

    private func flagOverlay(in size: CGSize) -> some View {
        VStack(spacing: size.height * 0.006) {
            Text(FootballCountry.flagEmoji(for: model.countryCode))
                .font(.system(size: size.width * 0.07))
            Text(model.countryCode.uppercased())
                .font(Theme.Typography.statLabel(size: size.width * 0.028))
                .foregroundStyle(style.accentBright.opacity(0.9))
                .tracking(0.8)
        }
        .shadow(color: .black.opacity(0.6), radius: 3, y: 1)
        .position(x: size.width * PlayerCardLayout.flagX, y: size.height * PlayerCardLayout.flagY)
        .accessibilityLabel(FootballCountry.name(for: model.countryCode))
    }

    private func statsOverlay(in size: CGSize) -> some View {
        ZStack {
            statColumn(
                left: true,
                size: size,
                entries: [
                    ("INT", model.displayStats.intValue),
                    ("SPD", model.displayStats.spdValue),
                ]
            )
            .position(x: size.width * PlayerCardLayout.statsLeftX, y: size.height * PlayerCardLayout.statsY)

            statColumn(
                left: false,
                size: size,
                entries: [
                    ("SPR", model.displayStats.sprValue),
                    ("KM", model.displayStats.kmValue),
                    ("MAT", model.displayStats.matValue),
                ]
            )
            .position(x: size.width * PlayerCardLayout.statsRightX, y: size.height * PlayerCardLayout.statsY)
        }
    }

    private func statColumn(
        left: Bool,
        size: CGSize,
        entries: [(String, String)]
    ) -> some View {
        VStack(alignment: left ? .leading : .trailing, spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
                if index > 0 {
                    Rectangle()
                        .fill(style.accent.opacity(0.35))
                        .frame(width: size.width * 0.14, height: 1)
                        .padding(.vertical, size.height * 0.012)
                }
                statBlock(abbrev: entry.0, value: entry.1, size: size, left: left)
            }
        }
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
        Text(model.displayName.uppercased())
            .font(Theme.Typography.display(size: size.width * 0.062))
            .foregroundStyle(style.ratingForeground)
            .tracking(1)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(maxWidth: size.width * 0.62)
            .shadow(color: .black.opacity(0.8), radius: 2, y: 2)
            .shadow(color: style.glow, radius: 6, y: 0)
            .position(x: size.width * 0.5, y: size.height * PlayerCardLayout.nameY)
    }

    private func tierLabelOverlay(in size: CGSize, text: String) -> some View {
        Text(text)
            .font(Theme.Typography.statLabel(size: size.width * 0.028))
            .foregroundStyle(style.accentBright)
            .tracking(1.4)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(Color.black.opacity(0.55))
            .clipShape(Capsule())
            .position(x: size.width * 0.5, y: size.height * PlayerCardLayout.tierLabelY)
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

#Preview("Bronze template") {
    PlayerProgressCard(model: previewModel(rank: .bronze))
        .padding()
        .background(Color.black)
}

#Preview("Gold template") {
    PlayerProgressCard(model: previewModel(rank: .gold))
        .padding()
        .background(Color.black)
}

#Preview("Holographic template") {
    PlayerProgressCard(model: previewModel(rank: .holographic))
        .padding()
        .background(Color.black)
}
