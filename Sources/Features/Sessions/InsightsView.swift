import ComposableArchitecture
import SwiftUI

struct InsightsView: View {
    @Bindable var store: StoreOf<InsightsFeature>

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                if store.isLoading, store.insights == nil {
                    loadingState
                } else if let error = store.errorMessage, store.insights == nil {
                    errorState(error)
                } else if let insights = store.insights {
                    insightsContent(insights)
                }
            }
            .rivalNavigationChrome(title: "Insights")
            .task { store.send(.onAppear) }
        }
        .tint(Theme.Colors.accent)
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
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                InsightsHeroCard(totals: insights.totals)

                if !store.recentSessions.isEmpty {
                    InsightsCharts.recentMatchesTrendCard(sessions: store.recentSessions)
                    InsightsCharts.matchRatingTrendCard(sessions: store.recentSessions)
                }

                InsightsCharts.averagesBarCard(averages: insights.averages)
                InsightsAveragesGrid(averages: insights.averages)

                if !insights.byMatchType.isEmpty {
                    InsightsCharts.breakdownCard(
                        title: "Match type",
                        groups: insights.byMatchType,
                        style: .donut
                    )
                }
                if !insights.bySurface.isEmpty {
                    InsightsCharts.breakdownCard(
                        title: "Surface",
                        groups: insights.bySurface,
                        style: .verticalBars
                    )
                }
                if !insights.byPosition.isEmpty {
                    InsightsCharts.breakdownCard(
                        title: "Position",
                        groups: insights.byPosition,
                        style: .line
                    )
                }
                if !insights.byMatchType.isEmpty, insights.byMatchType.contains(where: { $0.avgDistance != nil }) {
                    InsightsCharts.breakdownCard(
                        title: "Distance by type",
                        groups: insights.byMatchType,
                        style: .area
                    )
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

// MARK: - Averages grid

private struct InsightsAveragesGrid: View {
    let averages: StatsAverages

    private var items: [(label: String, value: String, icon: String, accent: Color)] {
        var rows: [(String, String, String, Color)] = []
        if let km = averages.distancePerMatch {
            rows.append(("Distance", formatDistance(km), "figure.run", Theme.Colors.accentBright))
        }
        if let duration = averages.durationPerMatch {
            rows.append(("Duration", formatDuration(Int(duration)), "clock.fill", Theme.Colors.accent))
        }
        if let sprints = averages.sprintsPerMatch {
            rows.append(("Sprints", String(format: "%.0f", sprints), "hare.fill", Color(red: 1, green: 0.85, blue: 0.35)))
        }
        if let intensity = averages.intensity {
            rows.append(("Intensity", String(format: "%.0f", intensity), "flame.fill", Theme.Colors.accent))
        }
        if let rating = averages.matchRating {
            rows.append(("Rating", String(format: "%.0f", rating), "star.fill", Color(red: 0.45, green: 0.85, blue: 1)))
        }
        return rows
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("PER MATCH")
                .font(Theme.Typography.statLabel(size: 10))
                .foregroundStyle(Theme.Colors.textSecondary)
                .tracking(1.2)

            if items.isEmpty {
                Text("Log more matches to see averages.")
                    .font(Theme.Typography.caption())
                    .foregroundStyle(Theme.Colors.textSecondary)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: Theme.Spacing.medium),
                        GridItem(.flexible(), spacing: Theme.Spacing.medium),
                    ],
                    spacing: Theme.Spacing.medium
                ) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        InsightsStatTile(
                            label: item.label,
                            value: item.value,
                            icon: item.icon,
                            accent: item.accent
                        )
                    }
                }
            }
        }
    }

    private func formatDistance(_ meters: Double) -> String {
        let km = meters / 1000
        if km >= 1 { return String(format: "%.1f km", km) }
        return "\(Int(meters)) m"
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        if minutes >= 60 { return "\(minutes / 60)h \(minutes % 60)m" }
        return "\(minutes)m"
    }
}

private struct InsightsStatTile: View {
    let label: String
    let value: String
    let icon: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(accent.opacity(0.18))
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(accent)
                }
                Spacer(minLength: 0)
            }

            Text(value)
                .font(Theme.Typography.metric(size: 26))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label.uppercased())
                .font(Theme.Typography.statLabel(size: 9))
                .foregroundStyle(Theme.Colors.textSecondary)
                .tracking(0.8)
        }
        .padding(Theme.Spacing.medium)
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [Theme.Colors.surface, Color(red: 0.1, green: 0.1, blue: 0.11)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        }
    }
}
