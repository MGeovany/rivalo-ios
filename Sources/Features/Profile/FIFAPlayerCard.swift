import SwiftUI
import UIKit

/// FIFA Ultimate Team–style player card for the saved profile.
struct FIFAPlayerCard: View {
    let model: PlayerCardModel

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.72, blue: 0.25),
                            Theme.Colors.accentBright,
                            Theme.Colors.accent,
                            Color(red: 0.55, green: 0.22, blue: 0.05),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Theme.Colors.accent.opacity(0.35), radius: 20, y: 10)

            RoundedRectangle(cornerRadius: 19)
                .fill(Theme.Colors.background)
                .padding(3)

            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    cardHero
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.55),
                            Color.black.opacity(0.05),
                            Color.clear,
                            Color.black.opacity(0.2),
                            Color.black.opacity(0.92),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    VStack(alignment: .leading, spacing: 0) {
                        ratingColumn
                            .padding(Theme.Spacing.medium)

                        Spacer(minLength: 0)

                        footer
                            .padding(.horizontal, Theme.Spacing.medium)
                            .padding(.bottom, Theme.Spacing.medium)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 19))
            }
        }
        .aspectRatio(0.68, contentMode: .fit)
        .frame(maxWidth: 360)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Hero (center of card)

    @ViewBuilder
    private var cardHero: some View {
        if let data = model.avatarImageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        } else {
            ZStack {
                LinearGradient(
                    colors: [
                        Theme.Colors.surface,
                        Theme.Colors.background,
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(spacing: Theme.Spacing.medium) {
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.surface)
                            .frame(width: 100, height: 100)
                        Circle()
                            .stroke(Theme.Colors.accent.opacity(0.5), lineWidth: 3)
                            .frame(width: 100, height: 100)

                        Text(model.initials)
                            .font(Theme.Typography.title(size: 38))
                            .foregroundStyle(Theme.Colors.textPrimary)
                    }

                    if let position = model.position, !position.isEmpty {
                        Text(position)
                            .font(Theme.Typography.caption(size: 12))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
        }
    }

    private var ratingColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let rating = model.rating {
                Text("\(rating)")
                    .font(Theme.Typography.metric(size: 56))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 1, green: 0.92, blue: 0.55), Theme.Colors.accentBright],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .monospacedDigit()
                    .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    VStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 40, height: 4)
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 40, height: 4)
                    }

                    Text("NO RECORD YET")
                        .font(Theme.Typography.statLabel(size: 9))
                        .foregroundStyle(Color.white.opacity(0.75))
                        .tracking(0.8)
                }
            }

            Text(model.positionAbbrev)
                .font(Theme.Typography.button(size: 15))
                .foregroundStyle(Theme.Colors.accentBright)
                .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
        }
    }

    private var footer: some View {
        VStack(spacing: Theme.Spacing.small) {
            if model.avatarImageData != nil,
               let position = model.position, !position.isEmpty {
                Text(position)
                    .font(Theme.Typography.caption(size: 12))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Text(model.displayName.uppercased())
                .font(Theme.Typography.title(size: 22))
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)

            statsRow
        }
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell("HT", model.heightLabel)
            statDivider
            statCell("WT", model.weightLabel)
            statDivider
            statCell("POS", model.positionAbbrev)
        }
        .padding(.vertical, Theme.Spacing.small)
        .background(Theme.Colors.surface.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
    }

    private func statCell(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(Theme.Typography.statLabel(size: 10))
                .foregroundStyle(Theme.Colors.textSecondary)
            Text(value)
                .font(Theme.Typography.button(size: 13))
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Theme.Colors.textSecondary.opacity(0.25))
            .frame(width: 1, height: 32)
    }
}

#Preview("With rating") {
    FIFAPlayerCard(
        model: PlayerCardModel(
            displayName: "Alex Rivera",
            position: "Midfielder",
            positionAbbrev: "CM",
            heightLabel: "178 cm",
            weightLabel: "72 kg",
            rating: 84,
            initials: "AR",
            avatarImageData: nil
        )
    )
    .padding()
    .background(Theme.Colors.background)
}

#Preview("No record") {
    FIFAPlayerCard(
        model: PlayerCardModel(
            displayName: "Alex Rivera",
            position: "Midfielder",
            positionAbbrev: "CM",
            heightLabel: "178 cm",
            weightLabel: "72 kg",
            rating: nil,
            initials: "AR",
            avatarImageData: nil
        )
    )
    .padding()
    .background(Theme.Colors.background)
}
