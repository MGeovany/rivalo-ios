import SwiftUI
import UIKit

/// Shareable player progress card — dark, modern, focused on real match metrics.
struct PlayerProgressCard: View {
    let model: PlayerCardModel

    var body: some View {
        VStack(spacing: 0) {
            heroSection
            identitySection
            ratingSection
            metricsGrid
            brandFooter
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(cardBorder)
        .shadow(color: Theme.Colors.accent.opacity(0.12), radius: 24, y: 12)
        .shadow(color: .black.opacity(0.45), radius: 16, y: 8)
        .aspectRatio(0.62, contentMode: .fit)
        .frame(maxWidth: 340)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Sections

    private var heroSection: some View {
        ZStack(alignment: .topTrailing) {
            ZStack(alignment: .bottom) {
                playerPhoto
                    .frame(height: 168)

                LinearGradient(
                    colors: [Color.clear, Theme.Colors.background.opacity(0.95)],
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
                        colors: [
                            Theme.Colors.accent.opacity(0.18),
                            Theme.Colors.surface,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 140
                    )

                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.04))
                            .frame(width: 96, height: 96)
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Theme.Colors.accent.opacity(0.7), Theme.Colors.accentBright.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 96, height: 96)
                        Text(model.initials)
                            .font(Theme.Typography.display(size: 38))
                            .foregroundStyle(Theme.Colors.textPrimary)
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
                        .foregroundStyle(Theme.Colors.accent)
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
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Colors.accentBright, Theme.Colors.accent],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .monospacedDigit()
                    .shadow(color: Theme.Colors.accent.opacity(0.35), radius: 12, y: 0)
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
                colors: [
                    Theme.Colors.accent.opacity(0.08),
                    Color.clear,
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Theme.Colors.accent.opacity(0.5), Theme.Colors.accent.opacity(0.1)],
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
            metricCell(
                label: "Top speed",
                value: formattedSpeed,
                icon: "bolt.fill"
            )
            metricCell(
                label: "Avg sprints",
                value: formattedSprints,
                icon: "hare.fill"
            )
            metricCell(
                label: "Avg distance",
                value: formattedDistance,
                icon: "figure.run"
            )
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
                .foregroundStyle(Theme.Colors.textSecondary.opacity(0.45))
                .tracking(3)
            Spacer()
            Text("Real progress")
                .font(Theme.Typography.statLabel(size: 9))
                .foregroundStyle(Theme.Colors.textSecondary.opacity(0.35))
                .tracking(0.8)
        }
        .padding(.horizontal, Theme.Spacing.medium)
        .padding(.vertical, 10)
        .background(Theme.Colors.surface.opacity(0.5))
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
                            colors: [Theme.Colors.accentBright, Theme.Colors.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: Theme.Colors.accent.opacity(0.45), radius: 8, y: 3)
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
                    .foregroundStyle(Theme.Colors.accent.opacity(0.85))
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
                        colors: [
                            Theme.Colors.surface,
                            Color(red: 0.09, green: 0.09, blue: 0.10),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var cardBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.10, green: 0.10, blue: 0.11),
                Theme.Colors.background,
                Theme.Colors.background,
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        Theme.Colors.accent.opacity(0.35),
                        Color.white.opacity(0.08),
                        Theme.Colors.accent.opacity(0.15),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
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

#Preview("With badge") {
    PlayerProgressCard(
        model: PlayerCardModel(
            displayName: "Geovany",
            position: "Midfielder",
            positionAbbrev: "CM",
            physicalRating: 74,
            topSpeedKmh: 25.0,
            avgSprints: 9,
            avgDistanceKm: 8.5,
            fatigueDropPct: -12,
            badge: .newPR,
            initials: "G",
            avatarImageData: nil
        )
    )
    .padding()
    .background(Theme.Colors.background)
}

#Preview("Empty metrics") {
    PlayerProgressCard(
        model: PlayerCardModel(
            displayName: "Alex",
            position: "Forward",
            positionAbbrev: "ST",
            physicalRating: nil,
            topSpeedKmh: nil,
            avgSprints: nil,
            avgDistanceKm: nil,
            fatigueDropPct: nil,
            badge: nil,
            initials: "A",
            avatarImageData: nil
        )
    )
    .padding()
    .background(Theme.Colors.background)
}
