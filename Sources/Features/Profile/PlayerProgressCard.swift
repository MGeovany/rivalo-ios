import SwiftUI
import UIKit

/// FUT-style player card with rank-colored frame, wing ribbons, and real metrics.
struct PlayerProgressCard: View {
    let model: PlayerCardModel

    private var style: PlayerCardRankStyle { model.rank.style }

    var body: some View {
        ZStack {
            FUTCardShape()
                .fill(style.frameGradient)
                .shadow(color: style.frameDeep.opacity(0.65), radius: 22, y: 12)
                .shadow(color: style.glow, radius: model.rank.isHolographic ? 24 : 8, y: 0)

            FUTCardShape()
                .fill(style.innerTint)
                .padding(6)

            cardContent
                .padding(7)
                .clipShape(FUTCardShape())

            if model.rank.isHolographic {
                CardRankHolographicEffect()
                    .clipShape(FUTCardShape())
                    .padding(6)
            }

            FUTCardShape()
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.65), Color.clear, style.frameDeep.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .padding(6)
        }
        .aspectRatio(0.715, contentMode: .fit)
        .frame(maxWidth: 340)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Layout

    private var cardContent: some View {
        ZStack {
            cardBackgroundPattern

            VStack(spacing: 0) {
                topBand
                    .frame(height: 86)

                ZStack(alignment: .bottom) {
                    heroWithRibbons
                    statsOverlay
                }
                .frame(maxHeight: .infinity)

                namePlate
                    .frame(height: 54)
            }
        }
    }

    private var cardBackgroundPattern: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width * 0.5, y: size.height * 0.3)
            for index in 0 ..< 24 {
                let angle = (Double(index) / 24.0) * 2 * .pi
                let end = CGPoint(
                    x: center.x + cos(angle) * size.width * 0.8,
                    y: center.y + sin(angle) * size.height * 0.85
                )
                var path = Path()
                path.move(to: center)
                path.addLine(to: end)
                context.stroke(path, with: .color(style.accent.opacity(0.04)), lineWidth: 0.5)
            }
        }
        .allowsHitTesting(false)
    }

    private var topBand: some View {
        HStack(alignment: .top) {
            ratingBlock
            Spacer(minLength: 8)
            flagBlock
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var ratingBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let rating = model.physicalRating {
                Text("\(rating)")
                    .font(Theme.Typography.display(size: 54))
                    .foregroundStyle(style.ratingForeground)
                    .tracking(-2)
                    .shadow(color: .black.opacity(0.7), radius: 2, y: 2)
                    .shadow(color: style.glow, radius: 6, y: 0)
            } else {
                Text("—")
                    .font(Theme.Typography.display(size: 44))
                    .foregroundStyle(Color.white.opacity(0.35))
            }

            Text(model.positionAbbrev)
                .font(Theme.Typography.button(size: 15))
                .foregroundStyle(style.accentBright)
                .tracking(1.5)
                .shadow(color: .black.opacity(0.55), radius: 2, y: 1)
                .padding(.top, -4)
        }
    }

    private var flagBlock: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 46, height: 46)
                Circle()
                    .stroke(style.accent.opacity(0.55), lineWidth: 1.5)
                    .frame(width: 46, height: 46)
                Text(FootballCountry.flagEmoji(for: model.countryCode))
                    .font(.system(size: 28))
            }
            .shadow(color: .black.opacity(0.45), radius: 4, y: 2)
            .accessibilityLabel(FootballCountry.name(for: model.countryCode))
        }
    }

    private var heroWithRibbons: some View {
        ZStack {
            playerPhotoBackground

            RankRibbonFrame(rank: model.rank, style: style)

            if model.avatarImageData == nil {
                playerPortrait
                    .frame(width: 118, height: 118)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [style.frameTop, style.frameDeep],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2.5
                            )
                    )
                    .shadow(color: style.glow, radius: 10, y: 2)
                    .offset(y: -18)
            }

            LinearGradient(
                colors: [style.innerTint.opacity(0.45), Color.clear, Color.black.opacity(0.92)],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var playerPhotoBackground: some View {
        Group {
            if let data = model.avatarImageData, let uiImage = UIImage(data: data) {
                GeometryReader { proxy in
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height * 1.12)
                        .offset(y: proxy.size.height * 0.03)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                }
            } else {
                RadialGradient(
                    colors: [style.accent.opacity(0.12), style.innerTint],
                    center: UnitPoint(x: 0.5, y: 0.35),
                    startRadius: 0,
                    endRadius: 180
                )
            }
        }
    }

    @ViewBuilder
    private var playerPortrait: some View {
        if let data = model.avatarImageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                RadialGradient(
                    colors: [style.accent.opacity(0.15), style.innerTint],
                    center: .center,
                    startRadius: 0,
                    endRadius: 70
                )
                Text(model.initials)
                    .font(Theme.Typography.display(size: 44))
                    .foregroundStyle(style.accentBright)
            }
        }
    }

    private var statsOverlay: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [style.accent.opacity(0.5), style.accent.opacity(0.15)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            HStack(alignment: .top, spacing: 0) {
                statColumn(left: true)
                Spacer(minLength: 0)
                statColumn(left: false)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.55), Color.black.opacity(0.9)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private func statColumn(left: Bool) -> some View {
        VStack(alignment: left ? .leading : .trailing, spacing: 6) {
            if left {
                statRow(abbrev: "SPD", value: formattedSpeed, left: true)
                statRow(abbrev: "DIST", value: formattedDistance, left: true)
            } else {
                statRow(abbrev: "SPR", value: formattedSprints, left: false)
                statRow(abbrev: "FD", value: formattedFatigueDrop, left: false, valueColor: fatigueDropColor)
            }
        }
    }

    private func statRow(
        abbrev: String,
        value: String,
        left: Bool,
        valueColor: Color = .white
    ) -> some View {
        HStack(spacing: 6) {
            if left {
                Text(abbrev)
                    .font(Theme.Typography.statLabel(size: 10))
                    .foregroundStyle(style.accentBright.opacity(0.9))
                    .frame(width: 30, alignment: .leading)
                Text(value)
                    .font(Theme.Typography.button(size: 17))
                    .foregroundStyle(valueColor)
                    .shadow(color: .black.opacity(0.8), radius: 2, y: 1)
            } else {
                Text(value)
                    .font(Theme.Typography.button(size: 17))
                    .foregroundStyle(valueColor)
                    .shadow(color: .black.opacity(0.8), radius: 2, y: 1)
                Text(abbrev)
                    .font(Theme.Typography.statLabel(size: 10))
                    .foregroundStyle(style.accentBright.opacity(0.9))
                    .frame(width: 30, alignment: .trailing)
            }
        }
    }

    private var namePlate: some View {
        ZStack {
            LinearGradient(
                colors: [style.frameTop, style.frameMid, style.frameDeep],
                startPoint: .top,
                endPoint: .bottom
            )

            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 1)
                .frame(maxHeight: .infinity, alignment: .top)

            VStack(spacing: 2) {
                Text(model.displayName.uppercased())
                    .font(Theme.Typography.display(size: 21))
                    .foregroundStyle(Color(red: 0.10, green: 0.06, blue: 0.02))
                    .tracking(1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 10)

                if let position = model.position, !position.isEmpty {
                    Text(position)
                        .font(Theme.Typography.statLabel(size: 10))
                        .foregroundStyle(Color.black.opacity(0.5))
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 7)
        }
    }

    // MARK: - Formatting

    private var formattedSpeed: String {
        guard let speed = model.topSpeedKmh else { return "—" }
        return String(format: "%.1f", speed)
    }

    private var formattedSprints: String {
        guard let sprints = model.avgSprints else { return "—" }
        return "\(sprints)"
    }

    private var formattedDistance: String {
        guard let km = model.avgDistanceKm else { return "—" }
        return String(format: "%.1f", km)
    }

    private var formattedFatigueDrop: String {
        guard let pct = model.fatigueDropPct else { return "—" }
        return String(format: "%+.0f%%", pct)
    }

    private var fatigueDropColor: Color {
        guard let pct = model.fatigueDropPct else { return .white }
        if pct <= -10 { return Theme.Colors.negative }
        if pct >= 0 { return Theme.Colors.positive }
        return .white
    }
}

// MARK: - Previews

private func previewModel(rank: PlayerCardRank, country: String = "MX") -> PlayerCardModel {
    PlayerCardModel(
        displayName: "Geovany",
        position: "Midfielder",
        positionAbbrev: "CM",
        matchCount: 17,
        rank: rank,
        tierProgress: 3,
        physicalRating: 74,
        topSpeedKmh: 26.3,
        avgSprints: 9,
        avgDistanceKm: 8.5,
        fatigueDropPct: nil,
        badge: nil,
        countryCode: country,
        initials: "G",
        avatarImageData: nil
    )
}

#Preview("Gold") {
    PlayerProgressCard(model: previewModel(rank: .gold))
        .padding()
        .background(Theme.Colors.background)
}

#Preview("Diamond") {
    PlayerProgressCard(model: previewModel(rank: .diamond))
        .padding()
        .background(Theme.Colors.background)
}

#Preview("Holographic") {
    PlayerProgressCard(model: previewModel(rank: .holographic, country: "AR"))
        .padding()
        .background(Theme.Colors.background)
}

#Preview("Bronze") {
    PlayerProgressCard(model: previewModel(rank: .bronze, country: "CA"))
        .padding()
        .background(Theme.Colors.background)
}
