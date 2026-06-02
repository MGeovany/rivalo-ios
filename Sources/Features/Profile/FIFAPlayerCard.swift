import SwiftUI
import UIKit

/// FIFA Ultimate Team–style gold player card with gyro-driven holographic shine.
struct FIFAPlayerCard: View {
    let model: PlayerCardModel

    var body: some View {
        ZStack {
            FUTCardShape()
                .fill(FUTCardPalette.goldFrame)
                .shadow(color: FUTCardPalette.goldDeep.opacity(0.55), radius: 18, y: 10)

            FUTCardShape()
                .fill(FUTCardPalette.innerField)
                .padding(5)

            cardContent
                .padding(6)
                .clipShape(FUTCardShape())

            CardHolographicEffect()
                .clipShape(FUTCardShape())
                .padding(5)

            FUTCardShape()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.65),
                            Color.clear,
                            Color.black.opacity(0.35),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .padding(5)
        }
        .aspectRatio(0.715, contentMode: .fit)
        .frame(maxWidth: 340)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Layout

    private var cardContent: some View {
        VStack(spacing: 0) {
            topBand
                .frame(height: 88)

            ZStack {
                playerHero
                statsOverlay
            }
            .frame(maxHeight: .infinity)

            namePlate
                .frame(height: 52)
        }
    }

    private var topBand: some View {
        HStack(alignment: .top, spacing: 0) {
            ratingBlock
            Spacer(minLength: 8)
            nationalityBlock
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
    }

    private var ratingBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let rating = model.rating {
                Text("\(rating)")
                    .font(Theme.Typography.metric(size: 52))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [FUTCardPalette.goldTop, FUTCardPalette.goldMid],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .monospacedDigit()
                    .shadow(color: .black.opacity(0.65), radius: 3, y: 2)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.45))
                    Text("—")
                        .font(Theme.Typography.metric(size: 40))
                        .foregroundStyle(Color.white.opacity(0.35))
                }
            }

            Text(model.positionAbbrev)
                .font(Theme.Typography.button(size: 16))
                .foregroundStyle(FUTCardPalette.goldTop)
                .shadow(color: .black.opacity(0.5), radius: 2, y: 1)

            if model.matchesPlayed > 0 {
                Text("\(model.matchesPlayed) MAT")
                    .font(Theme.Typography.statLabel(size: 9))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .tracking(0.6)
            }
        }
    }

    private var nationalityBlock: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(FootballCountry.flagEmoji(for: model.countryCode))
                .font(.system(size: 36))
                .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
                .accessibilityLabel(FootballCountry.name(for: model.countryCode))

            Text(model.countryCode.uppercased())
                .font(Theme.Typography.statLabel(size: 10))
                .foregroundStyle(Color.white.opacity(0.7))
                .tracking(1)
        }
    }

    private var playerHero: some View {
        ZStack {
            if let data = model.avatarImageData, let uiImage = UIImage(data: data) {
                GeometryReader { proxy in
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                }
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.13, blue: 0.16),
                        FUTCardPalette.innerField,
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.06))
                            .frame(width: 108, height: 108)
                        Circle()
                            .stroke(FUTCardPalette.goldMid.opacity(0.6), lineWidth: 2)
                            .frame(width: 108, height: 108)
                        Text(model.initials)
                            .font(Theme.Typography.title(size: 42))
                            .foregroundStyle(Color.white.opacity(0.9))
                    }
                }
            }

            LinearGradient(
                colors: [
                    Color.black.opacity(0.5),
                    Color.clear,
                    Color.clear,
                    Color.black.opacity(0.75),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        }
    }

    private var statsOverlay: some View {
        VStack {
            Spacer()
            HStack(alignment: .bottom, spacing: 0) {
                statColumn(model.leftStats, alignment: .leading)
                Spacer(minLength: 0)
                statColumn(model.rightStats, alignment: .trailing)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
            .background(
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.82)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private func statColumn(_ stats: [PlayerCardStat], alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 5) {
            ForEach(Array(stats.enumerated()), id: \.offset) { _, stat in
                HStack(spacing: 6) {
                    if alignment == .leading {
                        Text(stat.abbrev)
                            .font(Theme.Typography.statLabel(size: 11))
                            .foregroundStyle(FUTCardPalette.goldTop.opacity(0.85))
                            .frame(width: 28, alignment: .leading)
                        Text(stat.value)
                            .font(Theme.Typography.button(size: 17))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                    } else {
                        Text(stat.value)
                            .font(Theme.Typography.button(size: 17))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                        Text(stat.abbrev)
                            .font(Theme.Typography.statLabel(size: 11))
                            .foregroundStyle(FUTCardPalette.goldTop.opacity(0.85))
                            .frame(width: 28, alignment: .trailing)
                    }
                }
            }
        }
    }

    private var namePlate: some View {
        ZStack {
            FUTCardPalette.namePlate

            VStack(spacing: 2) {
                Text(model.displayName.uppercased())
                    .font(Theme.Typography.title(size: 20))
                    .foregroundStyle(Color(red: 0.12, green: 0.08, blue: 0.02))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .padding(.horizontal, 10)

                HStack(spacing: 12) {
                    miniBadge(model.heightLabel, title: "HT")
                    miniBadge(model.weightLabel, title: "WT")
                    if let position = model.position, !position.isEmpty {
                        Text(position)
                            .font(Theme.Typography.statLabel(size: 10))
                            .foregroundStyle(Color.black.opacity(0.55))
                            .lineLimit(1)
                    }
                }
            }
            .padding(.vertical, 6)
        }
    }

    private func miniBadge(_ value: String, title: String) -> some View {
        HStack(spacing: 3) {
            Text(title)
                .font(Theme.Typography.statLabel(size: 9))
                .foregroundStyle(Color.black.opacity(0.45))
            Text(value)
                .font(Theme.Typography.statLabel(size: 10))
                .foregroundStyle(Color.black.opacity(0.7))
        }
    }
}

#Preview("Gold card") {
    let stats = PlayerCardStatsBuilder.build(from: [])
    FIFAPlayerCard(
        model: PlayerCardModel(
            displayName: "Geovany",
            position: "Midfielder",
            positionAbbrev: "CM",
            heightLabel: "170 cm",
            weightLabel: "70 kg",
            rating: 74,
            matchesPlayed: 5,
            countryCode: "MX",
            leftStats: stats.left,
            rightStats: stats.right,
            initials: "G",
            avatarImageData: nil
        )
    )
    .padding()
    .background(Theme.Colors.background)
}
