import Charts
import SwiftUI

enum SessionDetailCharts {
    static func heartRateCard(_ samples: [SessionSample]) -> some View {
        chartCard(
            title: "Heart rate",
            subtitle: "Cardio load over the match",
            icon: "waveform.path.ecg"
        ) {
            Chart(samples) { sample in
                AreaMark(
                    x: .value("min", Double(sample.tOffsetS) / 60),
                    y: .value("bpm", sample.hr ?? 0)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.Colors.accent.opacity(0.45), Theme.Colors.accent.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                LineMark(
                    x: .value("min", Double(sample.tOffsetS) / 60),
                    y: .value("bpm", sample.hr ?? 0)
                )
                .foregroundStyle(Theme.Colors.accent)
                .interpolationMethod(.catmullRom)
            }
            .chartYScale(domain: .automatic(includesZero: false))
        }
    }

    static func speedCard(_ samples: [SessionSample]) -> some View {
        chartCard(
            title: "Speed",
            subtitle: "Pace and bursts (km/h)",
            icon: "speedometer"
        ) {
            Chart(samples) { sample in
                BarMark(
                    x: .value("min", Double(sample.tOffsetS) / 60),
                    y: .value("km/h", sample.speedKmh ?? 0)
                )
                .foregroundStyle(Theme.Colors.accentBright.gradient)
            }
        }
    }

    static func distanceCard(_ samples: [SessionSample], totalDistanceM: Double) -> some View {
        let cumulative = cumulativeDistance(samples: samples, totalDistanceM: totalDistanceM)
        return chartCard(
            title: "Distance",
            subtitle: "Cumulative km during the match",
            icon: "figure.run"
        ) {
            Chart(cumulative, id: \.minute) { point in
                LineMark(
                    x: .value("min", point.minute),
                    y: .value("km", point.km)
                )
                .foregroundStyle(Theme.Colors.positive)
                .interpolationMethod(.catmullRom)
            }
        }
    }

    static func intensityCard(intensity: Double) -> some View {
        chartCard(
            title: "Intensity",
            subtitle: "Overall effort score",
            icon: "flame.fill"
        ) {
            Chart {
                BarMark(x: .value("Match", "Effort"), y: .value("%", intensity))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Colors.accentBright, Theme.Colors.accent],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
            }
            .chartYScale(domain: 0...100)
            .frame(height: 120)
            .overlay(alignment: .trailing) {
                Text("\(Int(intensity.rounded()))%")
                    .font(Theme.Typography.metric(size: 36))
                    .foregroundStyle(Theme.Colors.accent)
                    .padding(.trailing, Theme.Spacing.medium)
            }
        }
    }

    private static func chartCard<Content: View>(
        title: String,
        subtitle: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(Theme.Colors.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title.uppercased())
                        .font(Theme.Typography.statLabel(size: 11))
                        .tracking(0.8)
                    Text(subtitle)
                        .font(Theme.Typography.caption(size: 12))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            content()
                .frame(height: 160)
        }
        .padding(Theme.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .foregroundStyle(Theme.Colors.textPrimary)
    }

    private static func cumulativeDistance(samples: [SessionSample], totalDistanceM: Double) -> [(minute: Double, km: Double)] {
        let sorted = samples.sorted { $0.tOffsetS < $1.tOffsetS }
        guard sorted.count >= 2 else {
            return [(0, totalDistanceM / 1000)]
        }
        var points: [(Double, Double)] = [(0, 0)]
        var cumM = 0.0
        for i in 1..<sorted.count {
            let prev = sorted[i - 1]
            let cur = sorted[i]
            let dt = max(1, cur.tOffsetS - prev.tOffsetS)
            let speedMS = (cur.speedKmh ?? prev.speedKmh ?? 8) / 3.6
            cumM += speedMS * Double(dt)
            points.append((Double(cur.tOffsetS) / 60, cumM / 1000))
        }
        if let last = points.last, last.1 < totalDistanceM / 1000 {
            points.append((last.0, totalDistanceM / 1000))
        }
        return points
    }
}
