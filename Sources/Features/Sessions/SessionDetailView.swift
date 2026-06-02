import ComposableArchitecture
import SwiftUI

struct SessionDetailView: View {
    @Bindable var store: StoreOf<SessionDetailFeature>

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                content
            }
            .navigationTitle("Session")
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
                VStack(spacing: Theme.Spacing.medium) {
                    Text(session.startedAt.formatted(date: .complete, time: .shortened))
                        .font(Theme.Typography.caption())
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    metric("Duration", session.durationText)
                    metric("Distance", session.distanceKmText)
                    if let hrAvg = session.hrAvg { metric("Avg HR", "\(hrAvg) bpm") }
                    if let hrMax = session.hrMax { metric("Max HR", "\(hrMax) bpm") }
                    if let speed = session.speedMaxKmh { metric("Max speed", String(format: "%.1f km/h", speed)) }
                    metric("Sprints", "\(session.sprints)")
                    if let intensity = session.intensity { metric("Intensity", String(format: "%.0f", intensity)) }
                    if let kcal = session.caloriesKcal { metric("Calories", String(format: "%.0f kcal", kcal)) }
                    metric("Source", session.source.capitalized)
                }
                .padding(Theme.Spacing.large)
            }
        } else {
            Text(store.errorMessage ?? "Not found")
                .font(Theme.Typography.body())
                .foregroundStyle(Theme.Colors.negative)
        }
    }

    private func metric(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(Theme.Typography.body())
                .foregroundStyle(Theme.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(Theme.Typography.metric(size: 20))
        }
        .padding(Theme.Spacing.medium)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }
}
