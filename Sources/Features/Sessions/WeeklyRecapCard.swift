import SwiftUI

/// Home card: this week's matches, distance, sprints and rating, with the change
/// vs the previous week.
struct WeeklyRecapCard: View {
    let recap: WeeklyRecap

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("THIS WEEK")
                .font(Theme.Typography.statLabel(size: 10))
                .foregroundStyle(Theme.Colors.accentBright.opacity(0.9))
                .tracking(1.4)

            HStack(spacing: Theme.Spacing.large) {
                metric("\(recap.current.matchCount)", "Matches", delta: deltaInt(recap.current.matchCount, recap.previous.matchCount))
                metric(kmText(recap.current.totalDistanceM), "Distance", delta: recap.distanceDeltaPct)
                metric("\(recap.current.totalSprints)", "Sprints", delta: deltaInt(recap.current.totalSprints, recap.previous.totalSprints))
                metric(recap.current.avgRating.map { String(format: "%.0f", $0) } ?? "—", "Rating", delta: recap.ratingDeltaPct)
            }
        }
        .padding(Theme.Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    @ViewBuilder
    private func metric(_ value: String, _ label: String, delta: Double?) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(Theme.Typography.metric(size: 20))
                .monospacedDigit()
            Text(label)
                .font(Theme.Typography.statLabel(size: 10))
                .foregroundStyle(Theme.Colors.textSecondary)
            if let delta, abs(delta) >= 1 {
                HStack(spacing: 2) {
                    Image(systemName: delta >= 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 8, weight: .bold))
                    Text(String(format: "%.0f%%", abs(delta)))
                        .font(Theme.Typography.caption(size: 10))
                        .monospacedDigit()
                }
                .foregroundStyle(delta >= 0 ? Theme.Colors.positive : Theme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func deltaInt(_ current: Int, _ previous: Int) -> Double? {
        guard previous > 0 else { return nil }
        return (Double(current) - Double(previous)) / Double(previous) * 100
    }

    private func kmText(_ meters: Double) -> String {
        String(format: "%.1f", meters / 1000)
    }
}
