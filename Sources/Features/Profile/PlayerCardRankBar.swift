import SwiftUI

/// Rank summary under the player card: tier name, animated progress segments
/// toward the next tier, and total matches.
struct PlayerCardRankBar: View {
    let model: PlayerCardModel

    @State private var appeared = false

    private var style: PlayerCardRankStyle { model.rank.style }

    private var nextRank: PlayerCardRank? {
        model.rank == .unranked ? .bronze : model.rank.nextRank()
    }

    private var filledSegments: Int {
        min(model.tierProgress, PlayerCardRank.matchesPerTier)
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.small) {
            HStack(alignment: .firstTextBaseline) {
                Text(model.rank.displayName.uppercased())
                    .font(Theme.Typography.statLabel(size: 12))
                    .foregroundStyle(style.accentBright)
                    .tracking(1.4)

                Spacer()

                Text(progressLabel)
                    .font(Theme.Typography.statLabel(size: 10))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .tracking(0.6)
            }

            HStack(spacing: 5) {
                ForEach(0..<PlayerCardRank.matchesPerTier, id: \.self) { index in
                    Capsule()
                        .fill(
                            index < filledSegments
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [style.accentBright, style.accent],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                : AnyShapeStyle(Color.white.opacity(0.08))
                        )
                        .frame(height: 5)
                        .scaleEffect(x: appeared || index >= filledSegments ? 1 : 0.2, anchor: .leading)
                        .opacity(appeared || index >= filledSegments ? 1 : 0)
                        .animation(
                            .spring(response: 0.45, dampingFraction: 0.8)
                                .delay(0.12 + Double(index) * 0.07),
                            value: appeared
                        )
                }
            }

            HStack {
                Text("\(model.matchCount) \(model.matchCount == 1 ? "partido" : "partidos")")
                    .font(Theme.Typography.caption(size: 11))
                    .foregroundStyle(Theme.Colors.textSecondary)
                Spacer()
            }
        }
        .padding(.horizontal, Theme.Spacing.medium)
        .padding(.vertical, Theme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color.white.opacity(0.04))
        )
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .strokeBorder(style.accent.opacity(0.25), lineWidth: 1)
        }
        .frame(maxWidth: 340)
        .onAppear { appeared = true }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Nivel \(model.rank.displayName), \(progressLabel)")
    }

    private var progressLabel: String {
        if let next = nextRank {
            return "\(filledSegments)/\(PlayerCardRank.matchesPerTier) → \(next.displayName.uppercased())"
        }
        return "NIVEL MÁXIMO"
    }
}

#Preview {
    VStack(spacing: 16) {
        PlayerCardRankBar(
            model: PlayerCardModel(
                displayName: "Alex Rivera",
                position: "Midfielder",
                positionAbbrev: "MC",
                matchCount: 13,
                rank: .silver,
                tierProgress: 4,
                physicalRating: 74,
                displayStats: .empty,
                countryCode: "HN",
                initials: "AR"
            )
        )
    }
    .padding()
    .background(Color.black)
}
