import ComposableArchitecture
import SwiftUI

struct InsightsView: View {
    @Bindable var store: StoreOf<InsightsFeature>

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                if store.isLoading {
                    ProgressView("Loading insights...")
                } else if let error = store.errorMessage {
                    VStack(spacing: 12) {
                        Text(error)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                        Button("Retry") { store.send(.onAppear) }
                            .buttonStyle(.bordered)
                    }
                    .padding()
                } else if let ins = store.insights {
                    ScrollView {
                        VStack(spacing: 20) {
                            totalsSection(ins)
                            averagesSection(ins)
                            contextSection(title: "By Match Type", groups: ins.byMatchType)
                            contextSection(title: "By Surface", groups: ins.bySurface)
                            contextSection(title: "By Position", groups: ins.byPosition)
                        }
                        .padding(.horizontal, Theme.Spacing.medium)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                }
            }
            .rivalNavigationChrome(title: "Insights")
            .task { store.send(.onAppear) }
        }
        .tint(Theme.Colors.accent)
    }

    private func totalsSection(_ ins: SessionInsights) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Totals")
                .font(Theme.Typography.button(size: 14))
                .foregroundStyle(Theme.Colors.textSecondary)

            HStack {
                statBox(value: "\(ins.totals.sessionCount)", label: "Matches")
                statBox(value: formatDistance(ins.totals.totalDistanceM), label: "Total Distance")
                statBox(value: formatDuration(ins.totals.totalDurationS), label: "Total Time")
                if let cals = ins.totals.totalCalories {
                    statBox(value: "\(Int(cals))", label: "Calories")
                }
            }
        }
        .padding(Theme.Spacing.medium)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private func averagesSection(_ ins: SessionInsights) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Per Match Average")
                .font(Theme.Typography.button(size: 14))
                .foregroundStyle(Theme.Colors.textSecondary)

            VStack(spacing: 10) {
                avgRow(label: "Distance", value: ins.averages.distancePerMatch.map { formatDistance($0) })
                avgRow(label: "Duration", value: ins.averages.durationPerMatch.map { formatDuration(Int($0)) })
                avgRow(label: "Sprints", value: ins.averages.sprintsPerMatch.map { String(format: "%.0f", $0) })
                avgRow(label: "Intensity", value: ins.averages.intensity.map { String(format: "%.0f", $0) })
                avgRow(label: "Match Rating", value: ins.averages.matchRating.map { String(format: "%.0f", $0) })
            }
        }
        .padding(Theme.Spacing.medium)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private func contextSection(title: String, groups: [ContextGroup]) -> some View {
        guard !groups.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(Theme.Typography.button(size: 14))
                    .foregroundStyle(Theme.Colors.textSecondary)

                ForEach(groups) { group in
                    contextRow(group)
                    if group.value != groups.last?.value {
                        Divider().padding(.leading, 60)
                    }
                }
            }
            .padding(Theme.Spacing.medium)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        )
    }

    private func contextRow(_ group: ContextGroup) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(group.value)
                    .font(Theme.Typography.body(size: 15))
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text("\(group.count) matches")
                    .font(Theme.Typography.caption(size: 12))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            Spacer()
            if let rating = group.avgMatchRating {
                Text(String(format: "%.0f", rating))
                    .font(Theme.Typography.title(size: 16))
                    .foregroundStyle(Theme.Colors.accent)
            }
        }
        .padding(.vertical, 6)
    }

    private func statBox(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.Typography.title(size: 18))
                .foregroundStyle(Theme.Colors.accent)
            Text(label)
                .font(Theme.Typography.caption(size: 10))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func avgRow(label: String, value: String?) -> some View {
        HStack {
            Text(label)
                .font(Theme.Typography.body(size: 14))
                .foregroundStyle(Theme.Colors.textPrimary)
            Spacer()
            Text(value ?? "—")
                .font(Theme.Typography.body(size: 14))
                .foregroundStyle(Theme.Colors.accent)
        }
    }

    private func formatDistance(_ m: Double) -> String {
        let km = m / 1000
        if km >= 1 { return String(format: "%.1f km", km) }
        return "\(Int(m)) m"
    }

    private func formatDuration(_ s: Int) -> String {
        let h = s / 3600
        let m = (s % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}
