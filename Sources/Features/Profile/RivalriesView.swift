import ComposableArchitecture
import SwiftUI

struct RivalriesView: View {
    @Bindable var store: StoreOf<RivalriesFeature>

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                content
            }
            .rivalNavigationChrome(title: "Rivalries")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        store.send(.dismissTapped)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back")
                                .font(Theme.Typography.body(size: 15))
                        }
                    }
                    .tint(Theme.Colors.accent)
                }
            }
            .task { store.send(.onAppear) }
        }
        .tint(Theme.Colors.accent)
        .foregroundStyle(Theme.Colors.textPrimary)
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoading, store.rivalries.isEmpty {
            loadingState
        } else if store.rivalries.isEmpty {
            emptyState
        } else {
            rivalriesContent
        }
    }

    private var loadingState: some View {
        VStack(spacing: Theme.Spacing.medium) {
            ProgressView()
                .tint(Theme.Colors.accent)
            Text("Loading rivalries…")
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.large) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.Colors.accentBright.opacity(0.3),
                                Theme.Colors.accent.opacity(0.1),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                Image(systemName: "person.2.slash")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(Theme.Colors.accent)
            }
            Text("No rivalries yet")
                .font(Theme.Typography.title(size: 22))
            Text("Play at least 2 matches against the same opponent to see your rivalry history here.")
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)
        }
        .padding(Theme.Spacing.xl)
    }

    private var rivalriesContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                if let error = store.errorMessage {
                    AuthInlineMessage(text: error, kind: .error)
                }

                RivalriesHeroBanner(count: store.rivalries.count)

                VStack(spacing: Theme.Spacing.medium) {
                    ForEach(store.rivalries) { rivalry in
                        RivalryCard(rivalry: rivalry)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.large)
            .padding(.top, Theme.Spacing.medium)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .refreshable { store.send(.onAppear) }
    }
}

// MARK: - Hero

private struct RivalriesHeroBanner: View {
    let count: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.medium) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.accentBright, Theme.Colors.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                Image(systemName: "person.2.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(count) \(count == 1 ? "rivalry" : "rivalries")")
                    .font(Theme.Typography.title(size: 18))
                Text("Head-to-head history by opponent")
                    .font(Theme.Typography.caption(size: 12))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Theme.Colors.accent.opacity(0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.card)
                        .strokeBorder(Theme.Colors.accent.opacity(0.25), lineWidth: 1)
                }
        )
    }
}

// MARK: - Card

private struct RivalryCard: View {
    let rivalry: Rivalry

    private var accent: Color {
        if rivalry.wins > rivalry.losses {
            return Theme.Colors.positive
        }
        if rivalry.losses > rivalry.wins {
            return Theme.Colors.negative
        }
        return Theme.Colors.accentBright
    }

    private var winRateFraction: Double {
        guard let rate = rivalry.winRate else { return 0 }
        return min(max(rate / 100, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            HStack(alignment: .center, spacing: Theme.Spacing.medium) {
                opponentAvatar

                VStack(alignment: .leading, spacing: 4) {
                    Text(rivalry.opponent)
                        .font(Theme.Typography.title(size: 17))
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)

                    Text("\(rivalry.matchCount) matches played")
                        .font(Theme.Typography.caption(size: 12))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                Spacer(minLength: 0)

                RecordPillGroup(wins: rivalry.wins, draws: rivalry.draws, losses: rivalry.losses)
            }

            if rivalry.winRate != nil {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("WIN RATE")
                            .font(Theme.Typography.statLabel(size: 9))
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .tracking(0.9)
                        Spacer()
                        Text("\(Int(rivalry.winRate ?? 0))%")
                            .font(Theme.Typography.metric(size: 14))
                            .foregroundStyle(accent)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [accent.opacity(0.85), accent],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(geo.size.width * winRateFraction, winRateFraction > 0 ? 8 : 0))
                        }
                    }
                    .frame(height: 5)
                }
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: Theme.Spacing.small),
                    GridItem(.flexible(), spacing: Theme.Spacing.small),
                ],
                spacing: Theme.Spacing.small
            ) {
                if let rating = rivalry.avgRating {
                    RivalryStatTile(
                        icon: "star.fill",
                        value: String(format: "%.0f", rating),
                        label: "Avg rating",
                        accent: Theme.Colors.accentBright
                    )
                }
                if let dist = rivalry.avgDistanceM {
                    RivalryStatTile(
                        icon: "figure.run",
                        value: String(format: "%.1f km", dist / 1000),
                        label: "Avg distance",
                        accent: Theme.Colors.accent
                    )
                }
                if let sprints = rivalry.avgSprints {
                    RivalryStatTile(
                        icon: "hare.fill",
                        value: "\(Int(sprints))",
                        label: "Avg sprints",
                        accent: Color(red: 0.45, green: 0.85, blue: 1)
                    )
                }
                RivalryStatTile(
                    icon: "sportscourt.fill",
                    value: "\(rivalry.matchCount)",
                    label: "Matches",
                    accent: Color(red: 1, green: 0.85, blue: 0.35)
                )
            }

            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textSecondary)
                Text("Last match · \(rivalry.lastPlayedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(Theme.Typography.caption(size: 11))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .padding(Theme.Spacing.large)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.Colors.surface,
                            Color(red: 0.1, green: 0.1, blue: 0.11),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    LinearGradient(
                        colors: [accent.opacity(0.45), Color.white.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }

    private var opponentAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.35), accent.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
            Text(String(rivalry.opponent.prefix(1)).uppercased())
                .font(Theme.Typography.title(size: 18))
                .foregroundStyle(accent)
        }
    }
}

private struct RecordPillGroup: View {
    let wins: Int
    let draws: Int
    let losses: Int

    var body: some View {
        HStack(spacing: 4) {
            RecordPill(letter: "W", count: wins, color: Theme.Colors.positive)
            RecordPill(letter: "D", count: draws, color: Theme.Colors.accentBright)
            RecordPill(letter: "L", count: losses, color: Theme.Colors.negative)
        }
    }
}

private struct RecordPill: View {
    let letter: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 1) {
            Text(letter)
                .font(Theme.Typography.statLabel(size: 8))
                .foregroundStyle(color)
            Text("\(count)")
                .font(Theme.Typography.metric(size: 13))
                .foregroundStyle(Theme.Colors.textPrimary)
        }
        .frame(minWidth: 28)
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct RivalryStatTile: View {
    let icon: String
    let value: String
    let label: String
    let accent: Color

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(accent.opacity(0.18))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(Theme.Typography.metric(size: 16))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(label.uppercased())
                    .font(Theme.Typography.statLabel(size: 8))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .tracking(0.6)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    RivalriesView(
        store: Store(
            initialState: RivalriesFeature.State(
                accessToken: "preview",
                rivalries: [
                    Rivalry(
                        opponent: "Halcones",
                        matchCount: 2,
                        wins: 2,
                        draws: 0,
                        losses: 0,
                        lastPlayedAt: Date(),
                        avgRating: 78,
                        avgDistanceM: 7200,
                        avgSprints: 9
                    ),
                    Rivalry(
                        opponent: "Atlético Centro",
                        matchCount: 2,
                        wins: 0,
                        draws: 1,
                        losses: 1,
                        lastPlayedAt: Date().addingTimeInterval(-86400 * 3),
                        avgRating: 74,
                        avgDistanceM: 8400,
                        avgSprints: 9
                    ),
                ]
            )
        ) {
            RivalriesFeature()
        }
    )
}
