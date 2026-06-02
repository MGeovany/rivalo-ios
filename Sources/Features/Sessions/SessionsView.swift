import Charts
import ComposableArchitecture
import SwiftUI

struct SessionsView: View {
    @Bindable var store: StoreOf<SessionsFeature>

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                content
            }
            .navigationTitle("History")
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
        } else if store.sessions.isEmpty {
            VStack(spacing: Theme.Spacing.small) {
                Text("No sessions yet")
                    .font(Theme.Typography.title())
                Text("Tap + to add a manual session")
                    .font(Theme.Typography.caption())
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        } else {
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.medium) {
                    if store.sessions.count >= 2 {
                        progressCard
                    }
                    averagesCard
                    ForEach(store.sessions) { session in
                        Button { store.send(.sessionTapped(session)) } label: {
                            row(session)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Theme.Spacing.large)
            }
        }
    }

    // MARK: Progress (distance over time)

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text("Distance progress")
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textSecondary)

            Chart(store.sessions.sorted { $0.startedAt < $1.startedAt }) { session in
                LineMark(
                    x: .value("Date", session.startedAt),
                    y: .value("km", session.distanceM / 1000)
                )
                .foregroundStyle(Theme.Colors.accent)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", session.startedAt),
                    y: .value("km", session.distanceM / 1000)
                )
                .foregroundStyle(Theme.Colors.accent)
            }
            .chartXAxis { AxisMarks(values: .automatic(desiredCount: 3)) }
            .frame(height: 160)
        }
        .padding(Theme.Spacing.medium)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    // MARK: Averages (comparative reference)

    private var averagesCard: some View {
        HStack {
            averageItem("Avg distance", store.averageDistanceKm.map { String(format: "%.2f km", $0) } ?? "--")
            Divider().overlay(Theme.Colors.textSecondary)
            averageItem("Avg duration", store.averageDurationMin.map { "\($0) min" } ?? "--")
            Divider().overlay(Theme.Colors.textSecondary)
            averageItem("Sessions", "\(store.sessions.count)")
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.medium)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private func averageItem(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.Typography.metric(size: 18))
                .foregroundStyle(Theme.Colors.accent)
                .monospacedDigit()
            Text(label)
                .font(Theme.Typography.statLabel(size: 11))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Row

    private func row(_ session: SportSession) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(Theme.Typography.body())
                Text(session.source.capitalized)
                    .font(Theme.Typography.statLabel())
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(session.durationText)
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.accent)
                Text(session.distanceKmText)
                    .font(Theme.Typography.statLabel())
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .padding(Theme.Spacing.medium)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .foregroundStyle(Theme.Colors.textPrimary)
    }
}
