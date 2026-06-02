import ComposableArchitecture
import SwiftUI

/// Compares sessions played at the same pitch: venue bests/averages plus a
/// per-session list with the focused session highlighted (V2-F.9).
struct PitchComparisonView: View {
    @Bindable var store: StoreOf<PitchComparisonFeature>

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                content
            }
            .rivalNavigationChrome(title: "Same court")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { store.send(.dismissTapped) }
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
        .foregroundStyle(Theme.Colors.textPrimary)
        .onAppear { store.send(.onAppear) }
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoading && store.sessions.isEmpty {
            LoadingView()
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                    header

                    if let stats = store.stats {
                        summaryGrid(stats)
                        sessionsList(stats)
                    } else {
                        emptyState
                    }

                    if let message = store.errorMessage {
                        AuthInlineMessage(text: message, kind: .error)
                    }
                }
                .padding(.horizontal, Theme.Spacing.large)
                .padding(.bottom, Theme.Spacing.xl)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Label(store.pitchName, systemImage: "sportscourt.fill")
                .font(Theme.Typography.title(size: 22))
            Text("^[\(store.samePitchSessions.count) session](inflect: true) at this court")
                .font(Theme.Typography.body(size: 14))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .padding(.top, Theme.Spacing.small)
    }

    private func summaryGrid(_ stats: PitchComparisonStats) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.small) {
            stat(kmText(stats.avgDistanceM), "Avg distance", "figure.run")
            stat(kmText(stats.bestDistanceM), "Best distance", "trophy.fill")
            stat(stats.avgRating.map { String(format: "%.0f", $0) } ?? "—", "Avg rating", "star.fill")
            stat(stats.bestRating.map { String(format: "%.0f", $0) } ?? "—", "Best rating", "crown.fill")
            stat(durationText(stats.avgDurationS), "Avg time", "clock.fill")
            stat("\(stats.count)", "Played here", "calendar")
        }
    }

    private func sessionsList(_ stats: PitchComparisonStats) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text("EVERY SESSION HERE")
                .font(Theme.Typography.statLabel(size: 11))
                .foregroundStyle(Theme.Colors.textSecondary)
                .tracking(1)

            ForEach(store.samePitchSessions) { session in
                sessionRow(
                    session,
                    isBest: session.id == stats.bestSessionId,
                    isFocused: session.id == store.focusedSessionId
                )
            }
        }
    }

    private func sessionRow(_ session: SportSession, isBest: Bool, isFocused: Bool) -> some View {
        HStack(spacing: Theme.Spacing.medium) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(session.startedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(Theme.Typography.body(size: 15))
                    if isBest {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.Colors.accent)
                    }
                }
                Text("\(session.distanceKmText) · \(session.durationText)")
                    .font(Theme.Typography.caption(size: 12))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            Spacer()
            if let rating = session.matchRating {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.0f", rating))
                        .font(Theme.Typography.metric(size: 20))
                        .monospacedDigit()
                        .foregroundStyle(Theme.Colors.accent)
                    Text("rating")
                        .font(Theme.Typography.caption(size: 10))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
        .padding(Theme.Spacing.medium)
        .background(isFocused ? Theme.Colors.accent.opacity(0.12) : Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(isFocused ? Theme.Colors.accent : .clear, lineWidth: 1)
        )
    }

    private var emptyState: some View {
        Text("No other sessions at this court yet.")
            .font(Theme.Typography.body(size: 15))
            .foregroundStyle(Theme.Colors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, Theme.Spacing.xl)
    }

    private func stat(_ value: String, _ label: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.accent)
            Text(value)
                .font(Theme.Typography.metric(size: 24))
                .monospacedDigit()
            Text(label)
                .font(Theme.Typography.statLabel(size: 11))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.medium)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private func kmText(_ meters: Double) -> String {
        String(format: "%.2f km", meters / 1000)
    }

    private func durationText(_ seconds: Double) -> String {
        "\(Int((seconds / 60).rounded())) min"
    }
}
