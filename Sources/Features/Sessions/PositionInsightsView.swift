import ComposableArchitecture
import SwiftUI

/// Physical comparison across positions with a prudent, non-prescriptive tone
/// (V2-J). Shows an insufficient-data state until the threshold is met.
struct PositionInsightsView: View {
    @Bindable var store: StoreOf<PositionInsightsFeature>

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                content
            }
            .rivalNavigationChrome(title: "Position insights")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { store.send(.dismissTapped) }
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .onAppear { store.send(.onAppear) }
        }
        .foregroundStyle(Theme.Colors.textPrimary)
        .tint(Theme.Colors.accent)
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoading, store.insights == nil {
            LoadingView()
        } else if let message = store.errorMessage, store.insights == nil {
            AuthInlineMessage(text: message, kind: .error)
                .padding(Theme.Spacing.large)
        } else if let insights = store.insights {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                    if insights.hasEnoughData {
                        comparisonsSection(insights)
                        positionsSection(insights.positions)
                        disclaimer
                    } else {
                        insufficientData(insights.positions)
                    }
                }
                .padding(.horizontal, Theme.Spacing.large)
                .padding(.top, Theme.Spacing.medium)
                .padding(.bottom, Theme.Spacing.xl)
            }
        }
    }

    @ViewBuilder
    private func comparisonsSection(_ insights: PositionInsights) -> some View {
        if let comparisons = insights.comparisons, !comparisons.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                Text("WHAT YOUR PHYSICAL DATA SHOWS")
                    .font(Theme.Typography.statLabel(size: 10))
                    .foregroundStyle(Theme.Colors.accentBright.opacity(0.9))
                    .tracking(1.2)

                ForEach(comparisons, id: \.self) { line in
                    HStack(alignment: .top, spacing: Theme.Spacing.medium) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.Colors.accent)
                            .frame(width: 22)
                        Text(line)
                            .font(Theme.Typography.body(size: 15))
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(Theme.Spacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        }
    }

    private func positionsSection(_ positions: [PositionStat]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text("AVERAGES BY POSITION")
                .font(Theme.Typography.statLabel(size: 11))
                .foregroundStyle(Theme.Colors.textSecondary)
                .tracking(1)

            ForEach(positions) { p in
                VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                    HStack {
                        Text(p.position.capitalized)
                            .font(Theme.Typography.body(size: 16))
                        Spacer()
                        Text("\(p.sessionCount) sessions")
                            .font(Theme.Typography.caption(size: 12))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    HStack(spacing: Theme.Spacing.large) {
                        metric(value: p.avgDistanceM.map { String(format: "%.1f km", $0 / 1000) }, label: "Distance")
                        metric(value: p.avgSprints.map { String(format: "%.0f", $0) }, label: "Sprints")
                        metric(value: p.avgIntensity.map { String(format: "%.0f", $0) }, label: "Intensity")
                    }
                }
                .padding(Theme.Spacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            }
        }
    }

    @ViewBuilder
    private func metric(value: String?, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value ?? "—")
                .font(Theme.Typography.metric(size: 18))
                .monospacedDigit()
            Text(label)
                .font(Theme.Typography.caption(size: 10))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    private var disclaimer: some View {
        Text("These are physical-load tendencies, not a verdict on your best position — and they reflect effort, not skill or tactics.")
            .font(Theme.Typography.caption(size: 12))
            .foregroundStyle(Theme.Colors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, Theme.Spacing.small)
    }

    private func insufficientData(_ positions: [PositionStat]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.Colors.accent)
                Text("Not enough data yet")
                    .font(Theme.Typography.title(size: 20))
                Text("We compare positions only with at least 3 sessions in each of 2 or more positions. Keep logging matches with your position to unlock this — and even then it stays a physical comparison, never a recommendation of where you should play.")
                    .font(Theme.Typography.body(size: 14))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Theme.Spacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))

            if !positions.isEmpty {
                positionsSection(positions)
            }
        }
    }
}
