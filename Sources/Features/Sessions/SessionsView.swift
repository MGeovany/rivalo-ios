import ComposableArchitecture
import SwiftUI

/// Home feed inspired by Strava: week strip, latest match, recent activities.
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
        .sheet(item: $store.scope(state: \.records, action: \.records)) { recordsStore in
            RecordsView(store: recordsStore)
        }
        .sheet(item: $store.scope(state: \.insights, action: \.insights)) { insightsStore in
            InsightsView(store: insightsStore)
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoading && store.sessions.isEmpty {
            LoadingView()
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    PerformanceSectionHeader()

                    if let message = store.errorMessage {
                        AuthInlineMessage(text: message, kind: .error)
                    }

                    performanceSection

                    SessionWeekStrip(sessions: store.sessions, referenceDate: Date())

                    if let latest = store.latestSession {
                        latestMatchSection(latest)
                    } else if store.isLoadingLatest {
                        ProgressView()
                            .tint(Theme.Colors.accent)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }

                    if store.sessions.isEmpty {
                        emptyHint
                    }

                    if !store.recentActivities.isEmpty {
                        recentActivitiesSection
                    }

                    recordsLink
                    insightsLink
                    analyticsLink
                }
                .padding(.horizontal, Theme.Spacing.large)
                .padding(.top, Theme.Spacing.medium)
                .padding(.bottom, Theme.Spacing.xl)
            }
            .refreshable { store.send(.onAppear) }
        }
    }

    private var performanceSection: some View {
        DashboardSummaryStrip(
            period: $store.performancePeriod,
            snapshot: store.performanceSnapshot
        )
    }

    private func latestMatchSection(_ session: SportSession) -> some View {
        let meta = SessionMetaStore.load(sessionId: session.id)
        return SessionLastMatchCard(
            session: session,
            meta: meta,
            onTap: { store.send(.sessionTapped(session)) }
        )
    }

    private var emptyHint: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text("No matches yet")
                .font(Theme.Typography.button(size: 16))
            Text("Record on your Watch or tap + to log a session.")
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .padding(Theme.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.surface.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private var recentActivitiesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("Recent activities")
                .font(Theme.Typography.button(size: 18))
                .foregroundStyle(Theme.Colors.textPrimary)

            ForEach(store.recentActivities) { session in
                Button { store.send(.sessionTapped(session)) } label: {
                    RecentActivityRow(
                        session: session,
                        meta: SessionMetaStore.load(sessionId: session.id)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var recordsLink: some View {
        Button { store.send(.recordsTapped) } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Personal Records")
                        .font(Theme.Typography.button(size: 16))
                    Text("Your best marks per category")
                        .font(Theme.Typography.caption(size: 12))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .padding(Theme.Spacing.medium)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .foregroundStyle(Theme.Colors.textPrimary)
        }
        .buttonStyle(.plain)
    }

    private var insightsLink: some View {
        Button { store.send(.insightsTapped) } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Insights")
                        .font(Theme.Typography.button(size: 16))
                    Text("Your stats by match type, surface, position")
                        .font(Theme.Typography.caption(size: 12))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .padding(Theme.Spacing.medium)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .foregroundStyle(Theme.Colors.textPrimary)
        }
        .buttonStyle(.plain)
    }

    private var analyticsLink: some View {
        NavigationLink {
            PerformanceAnalyticsView(sessions: store.sessions)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Match charts")
                        .font(Theme.Typography.button(size: 16))
                    Text("Distance, duration, HR and more over time")
                        .font(Theme.Typography.caption(size: 12))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .padding(Theme.Spacing.medium)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .foregroundStyle(Theme.Colors.textPrimary)
        }
    }
}

/// Compact Strava-style activity row.
struct RecentActivityRow: View {
    let session: SportSession
    let meta: SessionMeta

    var body: some View {
        HStack(spacing: Theme.Spacing.medium) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.Colors.accent.opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: session.source == "watch" ? "applewatch" : "figure.soccer")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.Colors.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(Theme.Typography.body(size: 15))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(SessionActivityGeometry.displayLocation(session: session, meta: meta))
                    .font(Theme.Typography.caption(size: 12))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .lineLimit(1)

                HStack(spacing: 10) {
                    metricChip(
                        String(format: "%.2f", session.distanceM / 1000),
                        unit: "km"
                    )
                    metricChip("\(session.durationS / 60)", unit: "min")
                    if let hr = session.hrAvg {
                        metricChip("\(hr)", unit: "bpm")
                    }
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.Colors.textSecondary.opacity(0.6))
        }
        .padding(Theme.Spacing.medium)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private func metricChip(_ value: String, unit: String) -> some View {
        HStack(spacing: 3) {
            Text(value)
                .font(Theme.Typography.statLabel(size: 11))
                .foregroundStyle(Theme.Colors.textSecondary)
                .monospacedDigit()
                .lineLimit(1)
            Text(unit)
                .font(Theme.Typography.statLabel(size: 10))
                .foregroundStyle(Theme.Colors.textSecondary.opacity(0.85))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

/// Full performance charts (moved off the main Home feed).
struct PerformanceAnalyticsView: View {
    let sessions: [SportSession]

    private var sorted: [SportSession] {
        sessions.sorted { $0.startedAt < $1.startedAt }
    }

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                    Text("Charts")
                        .font(Theme.Typography.statLabel(size: 11))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .tracking(1.2)

                    DashboardChartCard(title: "Distance", subtitle: "Km per match") {
                        HomeDashboardCharts.distanceLine(sessions: sorted)
                    }
                    DashboardChartCard(title: "Duration", subtitle: "Minutes per match") {
                        HomeDashboardCharts.durationBars(sessions: sorted)
                    }
                    DashboardChartCard(title: "Heart rate", subtitle: "Average BPM") {
                        HomeDashboardCharts.heartRateLine(sessions: sorted)
                    }
                    DashboardChartCard(title: "Intensity", subtitle: "Effort score") {
                        HomeDashboardCharts.intensityBars(sessions: sorted)
                    }
                    DashboardChartCard(title: "Sprints", subtitle: "Per match") {
                        HomeDashboardCharts.sprintsBars(sessions: sorted)
                    }
                }
                .padding(Theme.Spacing.large)
            }
        }
        .rivalNavigationChrome(title: "Charts")
        .foregroundStyle(Theme.Colors.textPrimary)
    }
}
