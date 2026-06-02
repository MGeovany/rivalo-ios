import ComposableArchitecture
import SwiftUI

/// Home dashboard: performance charts and a compact recent-matches list.
struct SessionsView: View {
    @Bindable var store: StoreOf<SessionsFeature>

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                content
            }
            .rivalNavigationChrome()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { store.send(.addTapped) } label: {
                        Image(systemName: "plus")
                    }
                    .tint(Theme.Colors.accent)
                }
            }
        }
        .tint(Theme.Colors.accent)
        .onAppear { store.send(.onAppear) }
        .sheet(item: $store.scope(state: \.entry, action: \.entry)) { entryStore in
            SessionEntryView(store: entryStore)
        }
        .sheet(item: $store.scope(state: \.detail, action: \.detail)) { detailStore in
            SessionDetailView(store: detailStore)
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoading && store.sessions.isEmpty {
            LoadingView()
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                    dashboardHeader

                    if let message = store.errorMessage {
                        AuthInlineMessage(text: message, kind: .error)
                    }

                    if store.sessions.isEmpty {
                        emptyDashboardHint
                    }

                    chartsSection

                    if !store.recentSessions.isEmpty {
                        recentSection
                    }
                }
                .padding(.horizontal, Theme.Spacing.large)
                .padding(.top, Theme.Spacing.small)
                .padding(.bottom, Theme.Spacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    // MARK: - Dashboard

    private var dashboardHeader: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("Performance")
                .font(Theme.Typography.title(size: 32))
                .foregroundStyle(Theme.Colors.textPrimary)

            Text("Your match trends at a glance")
                .font(Theme.Typography.body(size: 15))
                .foregroundStyle(Theme.Colors.textSecondary)

            DashboardSummaryStrip(
                sessions: store.sessions.count,
                totalKm: store.totalDistanceKm,
                avgMinutes: store.averageDurationMin,
                avgHr: store.averageHr
            )
        }
    }

    private var emptyDashboardHint: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text("No data yet")
                .font(Theme.Typography.button(size: 16))
                .foregroundStyle(Theme.Colors.textPrimary)
            Text("Record a match on your Watch or tap + to add one manually.")
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .padding(Theme.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.surface.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private var chartsSection: some View {
        let sorted = store.sortedSessions

        return VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("Charts")
                .font(Theme.Typography.statLabel(size: 11))
                .foregroundStyle(Theme.Colors.textSecondary)
                .tracking(1.2)

            DashboardChartCard(
                title: "Distance",
                subtitle: "Kilometers per match over time"
            ) {
                HomeDashboardCharts.distanceLine(sessions: sorted)
            }

            DashboardChartCard(
                title: "Duration",
                subtitle: "Minutes played each match"
            ) {
                HomeDashboardCharts.durationBars(sessions: sorted)
            }

            DashboardChartCard(
                title: "Heart rate",
                subtitle: "Average BPM per match"
            ) {
                HomeDashboardCharts.heartRateLine(sessions: sorted)
            }

            DashboardChartCard(
                title: "Intensity",
                subtitle: "Effort score (0–100)"
            ) {
                HomeDashboardCharts.intensityBars(sessions: sorted)
            }

            DashboardChartCard(
                title: "Sprints",
                subtitle: "High-speed efforts per match"
            ) {
                HomeDashboardCharts.sprintsBars(sessions: sorted)
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("Recent matches")
                .font(Theme.Typography.statLabel(size: 11))
                .foregroundStyle(Theme.Colors.textSecondary)
                .tracking(1.2)

            ForEach(store.recentSessions) { session in
                Button { store.send(.sessionTapped(session)) } label: {
                    recentRow(session)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func recentRow(_ session: SportSession) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(Theme.Typography.body(size: 15))
                Text(session.source.capitalized)
                    .font(Theme.Typography.statLabel(size: 11))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(session.distanceKmText)
                    .font(Theme.Typography.metric(size: 28))
                    .foregroundStyle(Theme.Colors.accent)
                    .monospacedDigit()
                Text(session.durationText)
                    .font(Theme.Typography.metric(size: 16))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .monospacedDigit()
            }
        }
        .padding(Theme.Spacing.medium)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .foregroundStyle(Theme.Colors.textPrimary)
    }
}
