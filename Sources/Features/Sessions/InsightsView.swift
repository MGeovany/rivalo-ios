import ComposableArchitecture
import SwiftUI

struct InsightsView: View {
    @Bindable var store: StoreOf<InsightsFeature>

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                if store.isLoading && store.insights == nil {
                    loadingState
                } else if let insights = store.insights {
                    if insights.totals.sessionCount == 0 {
                        emptyState
                    } else {
                        insightsContent(insights)
                    }
                } else if let error = store.errorMessage, !store.recentSessions.isEmpty {
                    errorState(error)
                } else if !store.isLoading {
                    emptyState
                }
            }
            .rivalNavigationChrome(title: "Insights")
            .task { store.send(.onAppear) }
        }
        .tint(Theme.Colors.accent)
        .sheet(item: $store.scope(state: \.positionInsights, action: \.positionInsights)) { positionStore in
            PositionInsightsView(store: positionStore)
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.large) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Theme.Colors.accent.opacity(0.5))

            VStack(spacing: Theme.Spacing.small) {
                Text("No insights yet")
                    .font(Theme.Typography.title(size: 20))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("Record your first match to start seeing your performance trends, distance, and activity patterns.")
                    .font(Theme.Typography.body(size: 15))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var loadingState: some View {
        VStack(spacing: Theme.Spacing.medium) {
            ProgressView()
                .tint(Theme.Colors.accent)
            Text("Loading insights…")
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: Theme.Spacing.large) {
            Text(message)
                .font(Theme.Typography.body())
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            Button("Retry") { store.send(.onAppear) }
                .font(Theme.Typography.button())
                .foregroundStyle(Color.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Theme.Colors.accent)
                .clipShape(Capsule())
        }
        .padding(Theme.Spacing.xl)
    }

    private func insightsContent(_ insights: SessionInsights) -> some View {
        let sessions = store.recentSessions
        let count = insights.totals.sessionCount
        let rating = InsightsAnalytics.ratingTrend(sessions: sessions)
        let sprints = InsightsAnalytics.sprintsTrend(sessions: sessions)
        let speed = InsightsAnalytics.topSpeedTrend(
            sessions: sessions,
            speedRecordSessionId: store.speedRecordSessionId
        )
        let fatigue = InsightsAnalytics.fatigueSummary(from: store.fatigueSessions)
        let byPosition = InsightsAnalytics.performanceRows(from: insights.byPosition)
        let byMatchType = InsightsAnalytics.performanceRows(
            from: insights.byMatchType,
            preferredOrder: InsightsAnalytics.matchTypeOrder
        )
        let consistency = InsightsAnalytics.consistency(sessions: sessions, totalCount: count)

        return ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                InsightsHeroCard(totals: insights.totals)

                if count < InsightsAnalytics.minMatchesForStrongCallouts {
                    InsightsEarlySampleBanner(
                        sessionCount: count,
                        needed: InsightsAnalytics.minMatchesForStrongCallouts
                    )
                }

                InsightsCharts.matchRatingTrendSection(
                    points: rating.points,
                    callout: rating.callout,
                    sessionCount: count
                )

                InsightsCharts.fatigueDropSection(
                    summary: fatigue,
                    isLoading: store.isLoadingFatigue && fatigue == nil
                )

                InsightsCharts.sprintsTrendSection(
                    points: sprints,
                    sessionCount: count
                )

                InsightsCharts.topSpeedTrendSection(
                    points: speed,
                    sessionCount: count
                )

                InsightsCharts.performanceSection(
                    title: "Performance by position",
                    rows: byPosition,
                    sessionCount: count
                )

                InsightsCharts.performanceSection(
                    title: "Performance by match type",
                    rows: byMatchType,
                    sessionCount: count
                )

                InsightsCharts.consistencySection(
                    summary: consistency,
                    sessionCount: count
                )

                if let rules = insights.insights, !rules.isEmpty, count >= InsightsAnalytics.minMatchesForStrongCallouts {
                    InsightsRulesCard(insights: rules)
                }

                Button {
                    store.send(.positionInsightsTapped)
                } label: {
                    Label("Position insights", systemImage: "figure.soccer")
                        .font(Theme.Typography.body(size: 15))
                        .frame(maxWidth: .infinity)
                        .padding(Theme.Spacing.medium)
                        .background(Theme.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                }
                .tint(Theme.Colors.accent)
            }
            .padding(.horizontal, Theme.Spacing.large)
            .padding(.top, Theme.Spacing.medium)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .refreshable { store.send(.onAppear) }
    }
}

// MARK: - Chrome

private struct InsightsEarlySampleBanner: View {
    let sessionCount: Int
    let needed: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.medium) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.Colors.accent)
            Text("\(sessionCount)/\(needed) matches — trends are indicative, not definitive.")
                .font(Theme.Typography.caption(size: 12))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .padding(Theme.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.accent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }
}

private struct InsightsRulesCard: View {
    let insights: [Insight]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("FROM YOUR DATA")
                .font(Theme.Typography.statLabel(size: 10))
                .foregroundStyle(Theme.Colors.accentBright.opacity(0.9))
                .tracking(1.2)

            ForEach(insights.prefix(2)) { insight in
                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .font(Theme.Typography.body(size: 14))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text(insight.detail)
                        .font(Theme.Typography.caption(size: 11))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
        .padding(Theme.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }
}

// MARK: - Hero

private struct InsightsHeroCard: View {
    let totals: StatsTotals

    private var totalKm: Double { totals.totalDistanceM / 1000 }

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.14, green: 0.08, blue: 0.04),
                            Theme.Colors.surface,
                            Theme.Colors.background,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ALL-TIME")
                            .font(Theme.Typography.statLabel(size: 10))
                            .foregroundStyle(Theme.Colors.accentBright.opacity(0.9))
                            .tracking(1.4)

                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("\(totals.sessionCount)")
                                .font(Theme.Typography.metric(size: 44))
                                .foregroundStyle(.white)
                                .monospacedDigit()
                            Text("matches")
                                .font(Theme.Typography.caption(size: 14))
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }

                    Spacer(minLength: 0)

                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.Colors.accentBright, Theme.Colors.accent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 52, height: 52)
                        Image(systemName: "sportscourt.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                Divider().overlay(Color.white.opacity(0.08))

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    AnimatedMetricText(value: totalKm, format: .decimal(fractionDigits: 1))
                        .font(Theme.Typography.metric(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Theme.Colors.accentBright],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .monospacedDigit()
                    Text("km total")
                        .font(Theme.Typography.caption(size: 14))
                        .foregroundStyle(Theme.Colors.accent)
                }

                Text(formatDuration(totals.totalDurationS))
                    .font(Theme.Typography.caption(size: 12))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .padding(Theme.Spacing.large)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Theme.Colors.accentBright.opacity(0.65),
                            Theme.Colors.accent.opacity(0.2),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m on pitch" }
        return "\(minutes)m on pitch"
    }
}
