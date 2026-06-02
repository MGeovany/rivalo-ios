import ComposableArchitecture
import SwiftUI

struct SessionDetailView: View {
    @Bindable var store: StoreOf<SessionDetailFeature>

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                content
            }
            .navigationTitle("Match summary")
            .navigationBarTitleDisplayMode(.inline)
        }
        .foregroundStyle(Theme.Colors.textPrimary)
        .onAppear { store.send(.onAppear) }
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoading {
            ProgressView().tint(Theme.Colors.accent)
        } else if let session = store.session {
            ScrollView {
                VStack(spacing: Theme.Spacing.large) {
                    hero(session)

                    LazyVGrid(columns: columns, spacing: Theme.Spacing.medium) {
                        card("Distance", session.distanceKmText, "figure.run")
                        card("Avg HR", session.hrAvg.map { "\($0)" } ?? "--", "heart.fill", unit: "bpm")
                        card("Max HR", session.hrMax.map { "\($0)" } ?? "--", "bolt.heart.fill", unit: "bpm")
                        card("Sprints", "\(session.sprints)", "hare.fill")
                        card("Intensity", session.intensity.map { String(format: "%.0f", $0) } ?? "--", "flame.fill")
                        card("Calories", session.caloriesKcal.map { String(format: "%.0f", $0) } ?? "--", "flame", unit: "kcal")
                    }
                }
                .padding(Theme.Spacing.large)
            }
        } else {
            Text(store.errorMessage ?? "Not found")
                .font(Theme.Typography.body())
                .foregroundStyle(Theme.Colors.negative)
        }
    }

    private func hero(_ session: SportSession) -> some View {
        VStack(spacing: Theme.Spacing.small) {
            Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textSecondary)
            Text(session.durationText)
                .font(Theme.Typography.metric(size: 52))
                .foregroundStyle(Theme.Colors.accent)
                .monospacedDigit()
            Text(session.source.capitalized)
                .font(Theme.Typography.statLabel())
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.medium)
    }

    private func card(_ label: String, _ value: String, _ icon: String, unit: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            HStack(spacing: 6) {
                Image(systemName: icon).foregroundStyle(Theme.Colors.accent)
                Text(label)
                    .font(Theme.Typography.caption())
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(Theme.Typography.metric(size: 26))
                    .monospacedDigit()
                if let unit {
                    Text(unit)
                        .font(Theme.Typography.statLabel())
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.medium)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }
}
