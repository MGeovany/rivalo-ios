import SwiftUI
import UIKit

/// Shareable player progress card — rank tier drives the visual design (LoL-style ladder).
struct PlayerProgressCard: View {
    let model: PlayerCardModel

    private var style: PlayerCardRankStyle { model.rank.style }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                rankHeader
                heroSection
                identitySection
                ratingSection
                metricsGrid
                brandFooter
            }

            if model.rank.isHolographic {
                CardRankHolographicEffect()
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(cardBorder)
        .overlay(rankFrameGlow)
        .shadow(color: style.glow, radius: model.rank.isHolographic ? 28 : 18, y: 10)
        .shadow(color: .black.opacity(0.45), radius: 16, y: 8)
        .aspectRatio(0.62, contentMode: .fit)
        .frame(maxWidth: 340)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Rank header

    private var rankHeader: some View {
        HStack(alignment: .center, spacing: 10) {
            rankEmblem

            VStack(alignment: .leading, spacing: 4) {
                Text(model.rank.displayName.uppercased())
                    .font(Theme.Typography.button(size: 13))
                    .foregroundStyle(style.accentBright)
                    .tracking(1.2)

                Text(rankProgressLabel)
                    .font(Theme.Typography.statLabel(size: 9))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer(minLength: 0)

            tierProgressPips
        }
        .padding(.horizontal, Theme.Spacing.medium)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [style.frameDeep.opacity(0.55), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var rankEmblem: some View {
        ZStack {
            Circle()
                .fill(style.frameGradient)
                .frame(width: 40, height: 40)
            Circle()
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                .frame(width: 40, height: 40)
            Image(systemName: rankIcon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(style.accentBright)
                .shadow(color: style.glow, radius: 4)
        }
    }

    private var rankIcon: String {
        switch model.rank {
        case .unranked: "questionmark"
        case .bronze: "shield.fill"
        case .silver: "shield.lefthalf.filled"
        case .gold: "crown.fill"
        case .platinum: "hexagon.fill"
        case .emerald: "leaf.fill"
        case .diamond: "diamond.fill"
        case .holographic: "sparkles"
        }
    }

    private var tierProgressPips: some View {
        HStack(spacing: 4) {
            ForEach(0 ..< PlayerCardRank.matchesPerTier, id: \.self) { index in
                Capsule()
                    .fill(index < model.tierProgress ? style.accent : Color.white.opacity(0.12))
                    .frame(width: 14, height: 4)
            }
        }
    }

    private var rankProgressLabel: String {
        if model.rank == .holographic {
            return "\(model.matchCount) matches · Max rank"
        }
        let next = model.rank == .unranked ? PlayerCardRank.bronze : model.rank.nextRank() ?? model.rank
        return "\(model.tierProgress)/\(PlayerCardRank.matchesPerTier) to \(next.displayName)"
    }

    // MARK: - Sections

    private var heroSection: some View {
        ZStack(alignment: .topTrailing) {
            ZStack(alignment: .bottom) {
                playerPhoto
                    .frame(height: 148)

                LinearGradient(
                    colors: [Color.clear, style.innerTint.opacity(0.95)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
            }

            if let badge = model.badge {
                progressBadge(badge)
                    .padding(14)
            }
        }
    }

    private var playerPhoto: some View {
        Group {
            if let data = model.avatarImageData, let uiImage = UIImage(data: data) {
                GeometryReader { proxy in
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height * 1.1)
                        .offset(y: proxy.size.height * 0.02)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                }
            } else {
                ZStack {
                    RadialGradient(
                        colors: [style.accent.opacity(0.2), style.innerTint],
                        center: .center,
                        startRadius: 0,
                        endRadius: 140
                    )

                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.04))
                            .frame(width: 96, height: 96)
                        Circle()
                            .stroke(style.borderGradient, lineWidth: 2)
                            .frame(width: 96, height: 96)
                        Text(model.initials)
                            .font(Theme.Typography.display(size: 38))
                            .foregroundStyle(style.accentBright)
                    }
                }
            }
        }
    }

    private var identitySection: some View {
        VStack(spacing: 4) {
            Text(model.displayName)
                .font(Theme.Typography.display(size: 26))
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            HStack(spacing: 6) {
                if let position = model.position, !position.isEmpty {
                    Text(position)
                        .font(Theme.Typography.caption(size: 13))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                if let position = model.position, !position.isEmpty, !model.positionAbbrev.isEmpty {
                    Text("·")
                        .foregroundStyle(Theme.Colors.textSecondary.opacity(0.5))
                }
                if !model.positionAbbrev.isEmpty {
                    Text(model.positionAbbrev)
                        .font(Theme.Typography.button(size: 13))
                        .foregroundStyle(style.accent)
                        .tracking(1.2)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.large)
        .padding(.bottom, Theme.Spacing.medium)
    }

    private var ratingSection: some View {
        VStack(spacing: 6) {
            Text("PHYSICAL RATING")
                .font(Theme.Typography.statLabel(size: 10))
                .foregroundStyle(Theme.Colors.textSecondary)
                .tracking(1.4)

            if let rating = model.physicalRating {
                Text("\(rating)")
                    .font(Theme.Typography.metric(size: 52))
                    .foregroundStyle(style.ratingForeground)
                    .monospacedDigit()
                    .shadow(color: style.glow, radius: 12, y: 0)
            } else {
                Text("—")
                    .font(Theme.Typography.metric(size: 44))
                    .foregroundStyle(Theme.Colors.textSecondary.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.medium)
        .background(
            LinearGradient(
                colors: [style.accent.opacity(0.1), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [style.accent.opacity(0.55), style.accent.opacity(0.08)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)
        }
    }

    private var metricsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
            ],
            spacing: 10
        ) {
            metricCell(label: "Top speed", value: formattedSpeed, icon: "bolt.fill")
            metricCell(label: "Avg sprints", value: formattedSprints, icon: "hare.fill")
            metricCell(label: "Avg distance", value: formattedDistance, icon: "figure.run")
            metricCell(
                label: "Fatigue drop",
                value: formattedFatigueDrop,
                icon: "arrow.down.right",
                valueColor: fatigueDropColor
            )
        }
        .padding(Theme.Spacing.medium)
    }

    private var brandFooter: some View {
        HStack {
            Text("RIVALO")
                .font(Theme.Typography.logo(size: 11))
                .foregroundStyle(style.accent.opacity(0.55))
                .tracking(3)
            Spacer()
            Text(model.rank.displayName.uppercased())
                .font(Theme.Typography.statLabel(size: 9))
                .foregroundStyle(style.accent.opacity(0.75))
                .tracking(1)
        }
        .padding(.horizontal, Theme.Spacing.medium)
        .padding(.vertical, 10)
        .background(style.frameDeep.opacity(0.35))
    }

    // MARK: - Components

    private func progressBadge(_ badge: PlayerCardBadge) -> some View {
        Text(badge.label)
            .font(Theme.Typography.statLabel(size: 9))
            .foregroundStyle(.white)
            .tracking(0.8)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [style.accentBright, style.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: style.glow, radius: 8, y: 3)
    }

    private func metricCell(
        label: String,
        value: String,
        icon: String,
        valueColor: Color = Theme.Colors.textPrimary
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(style.accent.opacity(0.9))
                Text(label.uppercased())
                    .font(Theme.Typography.statLabel(size: 9))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .tracking(0.6)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Text(value)
                .font(Theme.Typography.button(size: 20))
                .foregroundStyle(valueColor)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Theme.Colors.surface, style.innerTint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(style.accent.opacity(0.12), lineWidth: 1)
        )
    }

    private var cardBackground: some View {
        LinearGradient(
            colors: [
                style.innerTint.opacity(0.9),
                Theme.Colors.background,
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(style.borderGradient, lineWidth: model.rank.isHolographic ? 2 : 1.5)
    }

    private var rankFrameGlow: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(style.frameTop.opacity(0.35), lineWidth: 0.5)
            .padding(2)
            .opacity(model.rank == .unranked ? 0.4 : 1)
    }

    // MARK: - Formatting

    private var formattedSpeed: String {
        guard let speed = model.topSpeedKmh else { return "—" }
        return String(format: "%.1f km/h", speed)
    }

    private var formattedSprints: String {
        guard let sprints = model.avgSprints else { return "—" }
        return "\(sprints)"
    }

    private var formattedDistance: String {
        guard let km = model.avgDistanceKm else { return "—" }
        return String(format: "%.1f km", km)
    }

    private var formattedFatigueDrop: String {
        guard let pct = model.fatigueDropPct else { return "—" }
        return String(format: "%+.0f%%", pct)
    }

    private var fatigueDropColor: Color {
        guard let pct = model.fatigueDropPct else { return Theme.Colors.textPrimary }
        if pct <= -10 { return Theme.Colors.negative }
        if pct >= 0 { return Theme.Colors.positive }
        return Theme.Colors.textPrimary
    }
}

// MARK: - Previews

private func previewModel(
    rank: PlayerCardRank,
    matchCount: Int,
    tierProgress: Int,
    badge: PlayerCardBadge? = nil
) -> PlayerCardModel {
    PlayerCardModel(
        displayName: "Geovany",
        position: "Midfielder",
        positionAbbrev: "CM",
        matchCount: matchCount,
        rank: rank,
        tierProgress: tierProgress,
        physicalRating: 74,
        topSpeedKmh: 25.0,
        avgSprints: 9,
        avgDistanceKm: 8.5,
        fatigueDropPct: -12,
        badge: badge,
        initials: "G",
        avatarImageData: nil
    )
}

#Preview("Bronze") {
    PlayerProgressCard(model: previewModel(rank: .bronze, matchCount: 7, tierProgress: 3))
        .padding()
        .background(Theme.Colors.background)
}

#Preview("Gold") {
    PlayerProgressCard(model: previewModel(rank: .gold, matchCount: 17, tierProgress: 3))
        .padding()
        .background(Theme.Colors.background)
}

#Preview("Holographic") {
    PlayerProgressCard(model: previewModel(rank: .holographic, matchCount: 42, tierProgress: 5, badge: .newPR))
        .padding()
        .background(Theme.Colors.background)
}

#Preview("Unranked") {
    PlayerProgressCard(model: previewModel(rank: .unranked, matchCount: 3, tierProgress: 3))
        .padding()
        .background(Theme.Colors.background)
}
