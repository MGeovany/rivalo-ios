import Charts
import SwiftUI

enum InsightsChartStyle {
    case donut
    case verticalBars
    case horizontalBars
    case line
    case area
}

enum InsightsCharts {
    // MARK: - Trend (sessions)

    struct MatchTrendPoint: Identifiable {
        let index: Int
        let label: String
        let distanceKm: Double
        let rating: Double?

        var id: Int { index }
    }

    static func recentMatchesTrendCard(sessions: [SportSession]) -> some View {
        let points = trendPoints(from: sessions)
        return chartShell(
            title: "Recent matches",
            subtitle: "Distance per match (newest on the right)",
            icon: "chart.xyaxis.line"
        ) {
            if points.isEmpty {
                emptyChartPlaceholder("Log matches to see trends")
            } else {
                Chart(points) { point in
                    AreaMark(
                        x: .value("Match", point.label),
                        y: .value("km", point.distanceKm)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Colors.accent.opacity(0.35), Theme.Colors.accent.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    LineMark(
                        x: .value("Match", point.label),
                        y: .value("km", point.distanceKm)
                    )
                    .foregroundStyle(Theme.Colors.accentBright)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)
                    PointMark(
                        x: .value("Match", point.label),
                        y: .value("km", point.distanceKm)
                    )
                    .foregroundStyle(Theme.Colors.accent)
                    .symbolSize(40)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.08))
                        AxisValueLabel()
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .font(Theme.Typography.statLabel(size: 9))
                    }
                }
            }
        }
    }

    static func matchRatingTrendCard(sessions: [SportSession]) -> some View {
        let rated = sessions
            .filter { $0.matchRating != nil }
            .sorted { $0.startedAt < $1.startedAt }
            .suffix(8)
        return chartShell(
            title: "Match rating",
            subtitle: "Score trend (0–100)",
            icon: "star.fill"
        ) {
            if rated.isEmpty {
                emptyChartPlaceholder("Ratings appear after Watch matches")
            } else {
                Chart(Array(rated.enumerated()), id: \.element.id) { index, session in
                    BarMark(
                        x: .value("Match", shortLabel(for: session.startedAt, index: index)),
                        y: .value("Score", session.matchRating ?? 0)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.45, green: 0.85, blue: 1), Theme.Colors.accent],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(6)
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.08))
                        AxisValueLabel()
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Breakdowns (context groups)

    static func breakdownCard(
        title: String,
        groups: [ContextGroup],
        style: InsightsChartStyle
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text(title.uppercased())
                .font(Theme.Typography.statLabel(size: 10))
                .foregroundStyle(Theme.Colors.textSecondary)
                .tracking(1.2)

            chartShell(title: chartStyleLabel(style), subtitle: breakdownSubtitle(style), icon: chartIcon(style)) {
                if groups.isEmpty {
                    emptyChartPlaceholder("No data yet")
                } else {
                    switch style {
                    case .donut:
                        donutChart(groups: groups)
                    case .verticalBars:
                        verticalBarChart(groups: groups)
                    case .horizontalBars:
                        horizontalBarChart(groups: groups)
                    case .line:
                        lineChart(groups: groups, metric: \.avgIntensity)
                    case .area:
                        areaChart(groups: groups, metric: \.avgDistance)
                    }
                }
            }

            breakdownLegend(groups: groups)
        }
    }

    static func averagesBarCard(averages: StatsAverages) -> some View {
        let items: [(String, Double, String)] = [
            averages.distancePerMatch.map { ("Distance", $0 / 1000, "km") },
            averages.durationPerMatch.map { ("Duration", $0 / 60, "min") },
            averages.sprintsPerMatch.map { ("Sprints", $0, "") },
            averages.intensity.map { ("Intensity", $0, "%") },
            averages.matchRating.map { ("Rating", $0, "") },
        ].compactMap { $0 }

        return chartShell(
            title: "Per match",
            subtitle: "Average metrics compared",
            icon: "chart.bar.fill"
        ) {
            if items.isEmpty {
                emptyChartPlaceholder("Log more matches to see averages")
            } else {
                Chart(items, id: \.0) { item in
                    BarMark(
                        x: .value("Metric", item.0),
                        y: .value("Value", item.1)
                    )
                    .foregroundStyle(averageBarColor(for: item.0))
                    .cornerRadius(8)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.08))
                        AxisValueLabel()
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Private chart builders

    private static func donutChart(groups: [ContextGroup]) -> some View {
        Chart(groups) { group in
            SectorMark(
                angle: .value("Matches", group.count),
                innerRadius: .ratio(0.55),
                angularInset: 1.5
            )
            .foregroundStyle(donutColor(for: group, in: groups))
            .cornerRadius(4)
        }
    }

    private static func verticalBarChart(groups: [ContextGroup]) -> some View {
        Chart(groups) { group in
            BarMark(
                x: .value("Type", shortValue(group.value)),
                y: .value("Matches", group.count)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Theme.Colors.accentBright, Theme.Colors.accent],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .cornerRadius(6)
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.white.opacity(0.08))
                AxisValueLabel()
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
    }

    private static func horizontalBarChart(groups: [ContextGroup]) -> some View {
        Chart(groups) { group in
            BarMark(
                x: .value("Matches", group.count),
                y: .value("Type", shortValue(group.value))
            )
            .foregroundStyle(Theme.Colors.accent.gradient)
            .cornerRadius(6)
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.white.opacity(0.08))
                AxisValueLabel()
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
    }

    private static func lineChart(
        groups: [ContextGroup],
        metric: KeyPath<ContextGroup, Double?>
    ) -> some View {
        let points = groups.compactMap { group -> (String, Double)? in
            guard let value = group[keyPath: metric] else { return nil }
            return (shortValue(group.value), value)
        }
        return Group {
            if points.isEmpty {
                emptyChartPlaceholder("Intensity data not available")
            } else {
                Chart(points, id: \.0) { point in
                    LineMark(
                        x: .value("Type", point.0),
                        y: .value("Avg", point.1)
                    )
                    .foregroundStyle(Theme.Colors.accentBright)
                    .interpolationMethod(.catmullRom)
                    PointMark(
                        x: .value("Type", point.0),
                        y: .value("Avg", point.1)
                    )
                    .foregroundStyle(Theme.Colors.accent)
                    .symbolSize(50)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisValueLabel()
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
        }
    }

    private static func areaChart(
        groups: [ContextGroup],
        metric: KeyPath<ContextGroup, Double?>
    ) -> some View {
        let points = groups.compactMap { group -> (String, Double)? in
            guard let meters = group[keyPath: metric] else { return nil }
            return (shortValue(group.value), meters / 1000)
        }
        return Group {
            if points.isEmpty {
                emptyChartPlaceholder("Distance data not available")
            } else {
                Chart(points, id: \.0) { point in
                    AreaMark(
                        x: .value("Type", point.0),
                        y: .value("km", point.1)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Colors.positive.opacity(0.4), Theme.Colors.positive.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    LineMark(
                        x: .value("Type", point.0),
                        y: .value("km", point.1)
                    )
                    .foregroundStyle(Theme.Colors.positive)
                }
            }
        }
    }

    private static func breakdownLegend(groups: [ContextGroup]) -> some View {
        VStack(spacing: Theme.Spacing.small) {
            ForEach(groups) { group in
                HStack(spacing: Theme.Spacing.small) {
                    Text(group.value)
                        .font(Theme.Typography.body(size: 14))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text("\(group.count)")
                        .font(Theme.Typography.metric(size: 16))
                        .foregroundStyle(Theme.Colors.accent)
                        .monospacedDigit()
                    if let rating = group.avgMatchRating {
                        Text(String(format: "%.0f", rating))
                            .font(Theme.Typography.statLabel(size: 11))
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(Theme.Spacing.medium)
        .background(Theme.Colors.surface.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    // MARK: - Shell

    private static func chartShell<Content: View>(
        title: String,
        subtitle: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title.uppercased())
                        .font(Theme.Typography.statLabel(size: 10))
                        .tracking(0.8)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text(subtitle)
                        .font(Theme.Typography.caption(size: 11))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            content()
                .frame(height: 180)
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
        .foregroundStyle(Theme.Colors.textPrimary)
    }

    private static func emptyChartPlaceholder(_ text: String) -> some View {
        Text(text)
            .font(Theme.Typography.caption())
            .foregroundStyle(Theme.Colors.textSecondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private static func trendPoints(from sessions: [SportSession]) -> [MatchTrendPoint] {
        let recent = sessions.sorted { $0.startedAt < $1.startedAt }.suffix(8)
        return recent.enumerated().map { index, session in
            MatchTrendPoint(
                index: index,
                label: shortLabel(for: session.startedAt, index: index),
                distanceKm: session.distanceM / 1000,
                rating: session.matchRating
            )
        }
    }

    private static func shortLabel(for date: Date, index: Int) -> String {
        let day = date.formatted(.dateTime.day().month(.abbreviated))
        return "\(day)"
    }

    private static func shortValue(_ value: String) -> String {
        value.count > 10 ? String(value.prefix(9)) + "…" : value
    }

    private static func averageBarColor(for metric: String) -> Color {
        switch metric {
        case "Distance": Theme.Colors.accentBright
        case "Duration": Theme.Colors.accent
        case "Sprints": Color(red: 1, green: 0.85, blue: 0.35)
        case "Intensity": Theme.Colors.accent
        case "Rating": Color(red: 0.45, green: 0.85, blue: 1)
        default: Theme.Colors.accent
        }
    }

    private static func donutColor(for group: ContextGroup, in groups: [ContextGroup]) -> Color {
        let colors: [Color] = [
            Theme.Colors.accentBright,
            Theme.Colors.accent,
            Color(red: 1, green: 0.85, blue: 0.35),
            Color(red: 0.45, green: 0.85, blue: 1),
            Theme.Colors.positive,
        ]
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else {
            return Theme.Colors.accent
        }
        return colors[index % colors.count]
    }

    private static func chartStyleLabel(_ style: InsightsChartStyle) -> String {
        switch style {
        case .donut: "Distribution"
        case .verticalBars: "By count"
        case .horizontalBars: "Comparison"
        case .line: "Avg intensity"
        case .area: "Avg distance"
        }
    }

    private static func breakdownSubtitle(_ style: InsightsChartStyle) -> String {
        switch style {
        case .donut: "Share of matches"
        case .verticalBars: "Matches per category"
        case .horizontalBars: "Volume comparison"
        case .line: "Intensity across categories"
        case .area: "Distance across categories"
        }
    }

    private static func chartIcon(_ style: InsightsChartStyle) -> String {
        switch style {
        case .donut: "chart.pie.fill"
        case .verticalBars: "chart.bar.fill"
        case .horizontalBars: "chart.bar.xaxis"
        case .line: "chart.line.uptrend.xyaxis"
        case .area: "chart.line.uptrend.xyaxis"
        }
    }
}
