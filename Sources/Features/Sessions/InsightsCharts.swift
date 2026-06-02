import Charts
import SwiftUI

enum InsightsCharts {
    // MARK: - Sections

    static func matchRatingTrendSection(
        points: [InsightsAnalytics.MatchPoint],
        callout: InsightsAnalytics.TrendCallout?,
        sessionCount: Int
    ) -> some View {
        InsightsSection(
            title: "Match rating trend",
            footnote: sessionCount < InsightsAnalytics.minMatchesForStrongCallouts
                ? "Based on \(sessionCount) matches — early sample"
                : nil
        ) {
            if points.count < InsightsAnalytics.minMatchesForTrends {
                emptyState("Need at least \(InsightsAnalytics.minMatchesForTrends) rated matches")
            } else {
                VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                    if let callout {
                        TrendCalloutBadge(callout: callout)
                    }
                    Chart(points) { point in
                        LineMark(
                            x: .value("Match", point.label),
                            y: .value("Rating", point.value)
                        )
                        .foregroundStyle(Theme.Colors.accentBright)
                        .interpolationMethod(.catmullRom)
                        PointMark(
                            x: .value("Match", point.label),
                            y: .value("Rating", point.value)
                        )
                        .foregroundStyle(Theme.Colors.accent)
                        .symbolSize(45)
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
                    .frame(height: 160)
                }
            }
        }
    }

    static func fatigueDropSection(
        summary: InsightsAnalytics.FatigueSummary?,
        isLoading: Bool
    ) -> some View {
        InsightsSection(title: "Fatigue drop") {
            if isLoading {
                ProgressView().tint(Theme.Colors.accent).frame(maxWidth: .infinity, minHeight: 120)
            } else if let summary {
                VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(String(format: "%.0f%%", summary.dropPercent))
                            .font(Theme.Typography.metric(size: 36))
                            .foregroundStyle(summary.dropPercent > 12 ? Theme.Colors.negative : Theme.Colors.textPrimary)
                            .monospacedDigit()
                        Text("avg drop 1st → 2nd half")
                            .font(Theme.Typography.caption(size: 12))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    Chart {
                        BarMark(
                            x: .value("Half", "1st half"),
                            y: .value("Min", summary.firstHalfAvgMinutes)
                        )
                        .foregroundStyle(Theme.Colors.accent.gradient)
                        .cornerRadius(8)
                        BarMark(
                            x: .value("Half", "2nd half"),
                            y: .value("Min", summary.secondHalfAvgMinutes)
                        )
                        .foregroundStyle(Theme.Colors.positive.opacity(0.85))
                        .cornerRadius(8)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisValueLabel()
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }
                    .frame(height: 140)

                    Text("From \(summary.sessionCount) structured \(summary.sessionCount == 1 ? "match" : "matches") · high-intensity min per half")
                        .font(Theme.Typography.caption(size: 11))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            } else {
                emptyState("Structured matches with halves show fatigue here")
            }
        }
    }

    static func sprintsTrendSection(
        points: [InsightsAnalytics.MatchPoint],
        sessionCount: Int
    ) -> some View {
        InsightsSection(
            title: "Sprints trend",
            footnote: sessionCount < InsightsAnalytics.minMatchesForStrongCallouts ? "Early sample" : nil
        ) {
            if points.count < InsightsAnalytics.minMatchesForTrends {
                emptyState("Log a few matches with sprint data")
            } else {
                Chart(points) { point in
                    BarMark(
                        x: .value("Match", point.label),
                        y: .value("Sprints", point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 1, green: 0.85, blue: 0.35), Theme.Colors.accent],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(6)
                }
                .frame(height: 160)
            }
        }
    }

    static func topSpeedTrendSection(
        points: [InsightsAnalytics.MatchPoint],
        sessionCount: Int
    ) -> some View {
        InsightsSection(
            title: "Top speed trend",
            footnote: sessionCount < InsightsAnalytics.minMatchesForStrongCallouts ? "Early sample" : nil
        ) {
            if points.count < InsightsAnalytics.minMatchesForTrends {
                emptyState("Speed data appears on Watch matches")
            } else {
                Chart(points) { point in
                    LineMark(
                        x: .value("Match", point.label),
                        y: .value("km/h", point.value)
                    )
                    .foregroundStyle(Color(red: 1, green: 0.85, blue: 0.35))
                    .interpolationMethod(.catmullRom)
                    PointMark(
                        x: .value("Match", point.label),
                        y: .value("km/h", point.value)
                    )
                    .foregroundStyle(Color(red: 1, green: 0.85, blue: 0.35))
                    .symbolSize(point.isNewPR ? 70 : 40)
                    .annotation(position: .top, spacing: 2) {
                        if point.isNewPR {
                            Text("NEW PR")
                                .font(Theme.Typography.statLabel(size: 8))
                                .foregroundStyle(Theme.Colors.accentBright)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Theme.Colors.accent.opacity(0.25))
                                .clipShape(Capsule())
                        }
                    }
                }
                .frame(height: 170)
            }
        }
    }

    static func performanceSection(
        title: String,
        rows: [InsightsAnalytics.PerformanceRow],
        sessionCount: Int
    ) -> some View {
        InsightsSection(
            title: title,
            footnote: sessionCount < InsightsAnalytics.minMatchesForStrongCallouts ? "Scores may shift with more data" : nil
        ) {
            if rows.isEmpty {
                emptyState("Add match context to compare")
            } else {
                let maxScore = rows.map(\.avgScore).max() ?? 100
                VStack(spacing: Theme.Spacing.medium) {
                    ForEach(rows) { row in
                        PerformanceBarRow(row: row, maxScore: maxScore)
                    }
                }
            }
        }
    }

    static func consistencySection(
        summary: InsightsAnalytics.ConsistencySummary?,
        sessionCount: Int
    ) -> some View {
        InsightsSection(title: "Consistency") {
            if let summary {
                HStack(alignment: .center, spacing: Theme.Spacing.large) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.08), lineWidth: 8)
                        Circle()
                            .trim(from: 0, to: CGFloat(summary.score) / 100)
                            .stroke(
                                AngularGradient(
                                    colors: [Theme.Colors.accentBright, Theme.Colors.accent],
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                        Text("\(summary.score)%")
                            .font(Theme.Typography.metric(size: 28))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                    }
                    .frame(width: 88, height: 88)

                    Text(summary.detail)
                        .font(Theme.Typography.caption(size: 13))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if sessionCount < InsightsAnalytics.minMatchesForTrends {
                emptyState("Rate at least \(InsightsAnalytics.minMatchesForTrends) matches to see consistency")
            } else {
                emptyState("Match ratings unlock this insight")
            }
        }
    }

    // MARK: - Building blocks

    private struct InsightsSection<Content: View>: View {
        let title: String
        var footnote: String?
        @ViewBuilder var content: () -> Content

        var body: some View {
            VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title.uppercased())
                        .font(Theme.Typography.statLabel(size: 10))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .tracking(1.2)
                    if let footnote {
                        Text(footnote)
                            .font(Theme.Typography.caption(size: 11))
                            .foregroundStyle(Theme.Colors.textSecondary.opacity(0.85))
                    }
                }
                content()
            }
            .padding(Theme.Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(sectionBackground)
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
            }
        }

        private var sectionBackground: some View {
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(
                    LinearGradient(
                        colors: [Theme.Colors.surface, Color(red: 0.1, green: 0.1, blue: 0.11)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }

    private struct TrendCalloutBadge: View {
        let callout: InsightsAnalytics.TrendCallout

        var body: some View {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(callout.text)
                    .font(Theme.Typography.caption(size: 12))
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(foreground.opacity(0.12))
            .clipShape(Capsule())
        }

        private var icon: String {
            switch callout.tone {
            case .up: "arrow.up.right"
            case .down: "arrow.down.right"
            case .neutral: "minus"
            }
        }

        private var foreground: Color {
            switch callout.tone {
            case .up: Theme.Colors.positive
            case .down: Theme.Colors.negative
            case .neutral: Theme.Colors.textSecondary
            }
        }
    }

    private struct PerformanceBarRow: View {
        let row: InsightsAnalytics.PerformanceRow
        let maxScore: Double

        private var fraction: CGFloat {
            guard maxScore > 0 else { return 0 }
            return CGFloat(row.avgScore / maxScore)
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(row.value)
                        .font(Theme.Typography.body(size: 14))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(String(format: "%.0f", row.avgScore))
                        .font(Theme.Typography.metric(size: 16))
                        .foregroundStyle(Theme.Colors.accent)
                        .monospacedDigit()
                    Text("· \(row.matchCount)")
                        .font(Theme.Typography.caption(size: 11))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.06))
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.Colors.accentBright, Theme.Colors.accent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(8, proxy.size.width * fraction))
                    }
                }
                .frame(height: 8)
            }
        }
    }

    private static func emptyState(_ text: String) -> some View {
        Text(text)
            .font(Theme.Typography.caption())
            .foregroundStyle(Theme.Colors.textSecondary)
            .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
    }
}
