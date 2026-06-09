import ComposableArchitecture
import SwiftUI

/// Home feed inspired by Strava: week strip, latest match, records promo.
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

                    if let streaks = store.streaks, streaks.currentWeeks > 0 || !streaks.activeSpecials.isEmpty {
                        StreakCard(streaks: streaks)
                    }

                    if let recap = store.weeklyRecap, recap.current.matchCount > 0 {
                        WeeklyRecapCard(recap: recap)
                    }

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

                    PersonalRecordsHomeCard(
                        highlights: store.recordHighlights,
                        onTap: { store.send(.recordsTapped) }
                    )
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
            Text("Sin partidos aún")
                .font(Theme.Typography.button(size: 16))
            Text("Graba desde tu Watch o pulsa + para registrar un partido.")
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .padding(Theme.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.surface.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

}
