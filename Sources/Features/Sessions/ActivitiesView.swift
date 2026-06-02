import ComposableArchitecture
import SwiftUI

/// Full activity history (moved off Home).
struct ActivitiesView: View {
    @Bindable var store: StoreOf<SessionsFeature>

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                content
            }
            .rivalNavigationChrome(title: "Activities")
            .onAppear { store.send(.onAppear) }
        }
        .tint(Theme.Colors.accent)
        .sheet(item: $store.scope(state: \.detail, action: \.detail)) { detailStore in
            SessionDetailView(store: detailStore)
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoading && store.sessions.isEmpty {
            VStack(spacing: Theme.Spacing.medium) {
                ProgressView()
                    .tint(Theme.Colors.accent)
                Text("Loading activities…")
                    .font(Theme.Typography.caption())
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        } else if store.sessions.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.medium) {
                    ForEach(store.recentActivities) { session in
                        Button { store.send(.sessionTapped(session)) } label: {
                            ActivityListRow(
                                session: session,
                                meta: SessionMetaStore.load(sessionId: session.id)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Theme.Spacing.large)
                .padding(.top, Theme.Spacing.medium)
                .padding(.bottom, Theme.Spacing.xl)
            }
            .refreshable { store.send(.onAppear) }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.large) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.accent.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: "figure.run")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(Theme.Colors.accent)
            }
            Text("No activities yet")
                .font(Theme.Typography.title(size: 20))
            Text("Matches from your Watch or manual logs appear here.")
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.xl)
    }
}

/// Strava-style activity row for the Activities tab.
struct ActivityListRow: View {
    let session: SportSession
    let meta: SessionMeta

    var body: some View {
        HStack(spacing: Theme.Spacing.medium) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.Colors.accent.opacity(0.25),
                                Theme.Colors.accent.opacity(0.08),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 54, height: 54)
                Image(systemName: session.source == "watch" ? "applewatch" : "figure.soccer")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Theme.Colors.accent)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(Theme.Typography.body(size: 15))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(SessionActivityGeometry.displayLocation(session: session, meta: meta))
                    .font(Theme.Typography.caption(size: 12))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    metricChip(String(format: "%.2f", session.distanceM / 1000), unit: "km")
                    metricChip("\(session.durationS / 60)", unit: "min")
                    if let hr = session.hrAvg {
                        metricChip("\(hr)", unit: "bpm")
                    }
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.Colors.textSecondary.opacity(0.5))
        }
        .padding(Theme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(
                    LinearGradient(
                        colors: [Theme.Colors.surface, Color(red: 0.1, green: 0.1, blue: 0.11)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        }
    }

    private func metricChip(_ value: String, unit: String) -> some View {
        HStack(spacing: 3) {
            Text(value)
                .font(Theme.Typography.statLabel(size: 11))
                .foregroundStyle(Theme.Colors.textPrimary.opacity(0.9))
                .monospacedDigit()
            Text(unit)
                .font(Theme.Typography.statLabel(size: 10))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.05))
        .clipShape(Capsule())
    }
}
