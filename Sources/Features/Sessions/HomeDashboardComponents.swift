import Charts
import SwiftUI

// MARK: - Layout

struct DashboardSummaryStrip: View {
    let sessions: Int
    let totalKm: Double
    let avgMinutes: Int?
    let avgHr: Int?

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.medium) {
            DashboardStatTile(
                label: "Matches",
                value: "\(sessions)",
                icon: "sportscourt.fill"
            )
            DashboardStatTile(
                label: "Total distance",
                value: String(format: "%.1f", totalKm),
                unit: "km",
                icon: "figure.run"
            )
            DashboardStatTile(
                label: "Avg duration",
                value: avgMinutes.map { "\($0)" } ?? "—",
                unit: avgMinutes == nil ? nil : "min",
                icon: "clock.fill"
            )
            DashboardStatTile(
                label: "Avg heart rate",
                value: avgHr.map { "\($0)" } ?? "—",
                unit: avgHr == nil ? nil : "bpm",
                icon: "heart.fill"
            )
        }
    }
}

struct DashboardStatTile: View {
    let label: String
    let value: String
    var unit: String?
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.Colors.accent)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(Theme.Typography.metric(size: 38))
                    .foregroundStyle(Theme.Colors.accent)
                    .monospacedDigit()
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                if let unit {
                    Text(unit)
                        .font(Theme.Typography.statLabel(size: 14))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .padding(.bottom, 4)
                }
            }

            Text(label)
                .font(Theme.Typography.caption(size: 12))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.medium)
        .padding(.vertical, Theme.Spacing.small)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }
}

struct DashboardChartCard<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder var chart: () -> Content

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder chart: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.chart = chart
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.Typography.button(size: 16))
                    .foregroundStyle(Theme.Colors.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(Theme.Typography.caption(size: 12))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }

            chart()
        }
        .padding(Theme.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }
}

struct DashboardEmptyChart: View {
    let message: String

    var body: some View {
        Text(message)
            .font(Theme.Typography.caption())
            .foregroundStyle(Theme.Colors.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 140)
    }
}

// MARK: - Charts

enum HomeDashboardCharts {
    static let chartHeight: CGFloat = 180

    private static func dashboardYAxis() -> some AxisContent {
        AxisMarks { _ in
            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                .foregroundStyle(Theme.Colors.textSecondary.opacity(0.2))
            AxisValueLabel()
                .font(Theme.Typography.statLabel(size: 14))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    private static func dashboardXAxis() -> some AxisContent {
        AxisMarks(values: .automatic(desiredCount: 4)) { _ in
            AxisValueLabel()
                .font(Theme.Typography.statLabel(size: 12))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    @ViewBuilder
    static func distanceLine(sessions: [SportSession]) -> some View {
        if sessions.isEmpty {
            DashboardEmptyChart(message: "Record a match to see distance trends.")
        } else {
            Chart(sessions) { session in
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
            .chartXAxis { dashboardXAxis() }
            .chartYAxis { dashboardYAxis() }
            .frame(height: chartHeight)
        }
    }

    @ViewBuilder
    static func durationBars(sessions: [SportSession]) -> some View {
        if sessions.isEmpty {
            DashboardEmptyChart(message: "Duration per match will appear here.")
        } else {
            Chart(sessions) { session in
                BarMark(
                    x: .value("Date", session.startedAt),
                    y: .value("min", session.durationS / 60)
                )
                .foregroundStyle(Theme.Colors.accent.gradient)
            }
            .chartXAxis { dashboardXAxis() }
            .chartYAxis { dashboardYAxis() }
            .frame(height: chartHeight)
        }
    }

    @ViewBuilder
    static func heartRateLine(sessions: [SportSession]) -> some View {
        let withHr = sessions.filter { $0.hrAvg != nil }
        if withHr.isEmpty {
            DashboardEmptyChart(message: "Heart rate data needs a Watch-recorded match.")
        } else {
            Chart(withHr) { session in
                LineMark(
                    x: .value("Date", session.startedAt),
                    y: .value("bpm", session.hrAvg ?? 0)
                )
                .foregroundStyle(Theme.Colors.accentBright)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", session.startedAt),
                    y: .value("bpm", session.hrAvg ?? 0)
                )
                .foregroundStyle(Theme.Colors.accentBright)
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .chartXAxis { dashboardXAxis() }
            .chartYAxis { dashboardYAxis() }
            .frame(height: chartHeight)
        }
    }

    @ViewBuilder
    static func intensityBars(sessions: [SportSession]) -> some View {
        let withIntensity = sessions.filter { $0.intensity != nil }
        if withIntensity.isEmpty {
            DashboardEmptyChart(message: "Intensity scores appear after tracked matches.")
        } else {
            Chart(withIntensity) { session in
                BarMark(
                    x: .value("Date", session.startedAt),
                    y: .value("%", session.intensity ?? 0)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.Colors.accentBright, Theme.Colors.accent],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            }
            .chartYScale(domain: 0...100)
            .chartXAxis { dashboardXAxis() }
            .chartYAxis { dashboardYAxis() }
            .frame(height: chartHeight)
        }
    }

    @ViewBuilder
    static func sprintsBars(sessions: [SportSession]) -> some View {
        if sessions.isEmpty {
            DashboardEmptyChart(message: "Sprint counts will chart here.")
        } else {
            Chart(sessions) { session in
                BarMark(
                    x: .value("Date", session.startedAt),
                    y: .value("sprints", session.sprints)
                )
                .foregroundStyle(Theme.Colors.accent.opacity(0.85))
            }
            .chartXAxis { dashboardXAxis() }
            .chartYAxis { dashboardYAxis() }
            .frame(height: chartHeight)
        }
    }

}
