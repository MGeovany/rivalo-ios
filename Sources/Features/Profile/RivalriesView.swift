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
                    Button("Close") { store.send(.dismissTapped) }
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .onAppear { store.send(.onAppear) }
        }
        .foregroundStyle(Theme.Colors.textPrimary)
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoading, store.rivalries.isEmpty {
            LoadingView()
        } else if store.rivalries.isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(spacing: Theme.Spacing.medium) {
                    if let error = store.errorMessage {
                        AuthInlineMessage(text: error, kind: .error)
                    }
                    ForEach(store.rivalries) { rivalry in
                        rivalryCard(rivalry)
                    }
                }
                .padding(.horizontal, Theme.Spacing.large)
                .padding(.top, Theme.Spacing.medium)
                .padding(.bottom, Theme.Spacing.xl)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.medium) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 40))
                .foregroundStyle(Theme.Colors.textSecondary)
            Text("No rivalries yet")
                .font(Theme.Typography.body(size: 18))
            Text("Play at least 2 matches against the same opponent to see your rivalry history here.")
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private func rivalryCard(_ rivalry: Rivalry) -> some View {
        VStack(spacing: Theme.Spacing.small) {
            HStack {
                Text(rivalry.opponent)
                    .font(Theme.Typography.body(size: 18).weight(.bold))
                Spacer()
                recordBadge(wins: rivalry.wins, draws: rivalry.draws, losses: rivalry.losses)
            }

            HStack(spacing: 16) {
                statChip(label: "Matches", value: "\(rivalry.matchCount)")
                if let winRate = rivalry.winRate {
                    statChip(label: "Win rate", value: "\(Int(winRate))%")
                }
                if let rating = rivalry.avgRating {
                    statChip(label: "Avg rating", value: String(format: "%.0f", rating))
                }
            }

            HStack(spacing: 16) {
                if let dist = rivalry.avgDistanceM {
                    statChip(label: "Avg distance", value: String(format: "%.1f km", dist / 1000))
                }
                if let sprints = rivalry.avgSprints {
                    statChip(label: "Avg sprints", value: "\(Int(sprints))")
                }
                Spacer()
            }

            Text("Last match: \(rivalry.lastPlayedAt.formatted(date: .abbreviated, time: .omitted))")
                .font(Theme.Typography.caption(size: 11))
                .foregroundStyle(Theme.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Theme.Spacing.medium)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private func recordBadge(wins: Int, draws: Int, losses: Int) -> some View {
        HStack(spacing: 4) {
            Text("W")
                .font(Theme.Typography.caption(size: 11).weight(.bold))
                .foregroundStyle(.green)
            Text("\(wins)")
                .font(Theme.Typography.caption(size: 11))
            Text("D")
                .font(Theme.Typography.caption(size: 11).weight(.bold))
                .foregroundStyle(.yellow)
            Text("\(draws)")
                .font(Theme.Typography.caption(size: 11))
            Text("L")
                .font(Theme.Typography.caption(size: 11).weight(.bold))
                .foregroundStyle(.red)
            Text("\(losses)")
                .font(Theme.Typography.caption(size: 11))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Theme.Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func statChip(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(Theme.Typography.metric(size: 14))
            Text(label)
                .font(Theme.Typography.statLabel(size: 9))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }
}
