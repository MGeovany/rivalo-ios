import SwiftUI

// MARK: - Performance dashboard

struct DashboardSummaryStrip: View {
    @Binding var period: PerformancePeriod
    let snapshot: PerformanceSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            PerformancePeriodPicker(selection: $period)

            PerformanceHeroMetric(
                value: snapshot.totalDistanceKm,
                unit: "km",
                label: "Distancia total recorrida",
                icon: "figure.run",
                footnote: snapshot.sessionCount > 0
                    ? "\(snapshot.sessionCount) \(snapshot.sessionCount == 1 ? "partido registrado" : "partidos registrados")"
                    : "Sin partidos en este período"
            )

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: Theme.Spacing.medium),
                    GridItem(.flexible(), spacing: Theme.Spacing.medium),
                ],
                spacing: Theme.Spacing.medium
            ) {
                PerformanceStatCard(
                    label: "Velocidad máxima",
                    value: snapshot.topSpeedKmh,
                    format: .decimal(fractionDigits: 1),
                    unit: snapshot.topSpeedKmh == nil ? nil : "km/h",
                    icon: "bolt.fill",
                    style: .speed,
                    kind: .record
                )
                PerformanceStatCard(
                    label: "Sprints medios",
                    value: snapshot.avgSprints.map(Double.init),
                    format: .integer,
                    unit: nil,
                    icon: "hare.fill",
                    style: .sprints,
                    kind: .average
                )
                PerformanceStatCard(
                    label: "Distancia sprint",
                    value: snapshot.avgSprintDistanceKm,
                    format: .decimal(fractionDigits: 1),
                    unit: snapshot.avgSprintDistanceKm == nil ? nil : "km",
                    icon: "arrow.up.forward",
                    style: .sprintDistance,
                    kind: .average
                )
                PerformanceStatCard(
                    label: "Media por partido",
                    value: snapshot.avgKmPerMatch,
                    format: .decimal(fractionDigits: 1),
                    unit: snapshot.avgKmPerMatch == nil ? nil : "km",
                    icon: "figure.run",
                    style: .pace,
                    kind: .average
                )
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: period)
    }
}

struct PerformancePeriodPicker: View {
    @Binding var selection: PerformancePeriod

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.small) {
                ForEach(PerformancePeriod.allCases) { period in
                    Button {
                        selection = period
                    } label: {
                        Text(period.rawValue)
                            .font(Theme.Typography.caption(size: 13))
                            .foregroundStyle(selection == period ? Color.black : Theme.Colors.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selection == period ? Theme.Colors.accent : Theme.Colors.surface)
                            )
                            .overlay {
                                if selection != period {
                                    Capsule()
                                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct PerformanceMetricBadge: View {
    let text: String
    let kind: PerformanceMetricKind

    var body: some View {
        Text(text)
            .font(Theme.Typography.statLabel(size: 8))
            .foregroundStyle(foreground)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(background)
            .clipShape(Capsule())
    }

    private var foreground: Color {
        switch kind {
        case .total: Theme.Colors.textSecondary
        case .average: Theme.Colors.accentBright
        case .record: Color(red: 1, green: 0.85, blue: 0.35)
        }
    }

    private var background: Color {
        switch kind {
        case .total: Color.white.opacity(0.08)
        case .average: Theme.Colors.accent.opacity(0.2)
        case .record: Color(red: 1, green: 0.75, blue: 0.2).opacity(0.2)
        }
    }
}

/// Full-width headline stat for total distance.
private struct PerformanceHeroMetric: View {
    let value: Double
    let unit: String
    let label: String
    let icon: String
    let footnote: String?

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.14, green: 0.08, blue: 0.04),
                            Theme.Colors.surface,
                            Theme.Colors.background,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            HStack(alignment: .center, spacing: Theme.Spacing.medium) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(label.uppercased())
                        .font(Theme.Typography.statLabel(size: 10))
                        .foregroundStyle(Theme.Colors.accentBright.opacity(0.9))
                        .tracking(1.4)

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        AnimatedMetricText(value: value, format: .decimal(fractionDigits: 1))
                            .font(Theme.Typography.metric(size: 56))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Theme.Colors.accentBright],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .monospacedDigit()
                            .shadow(color: Theme.Colors.accent.opacity(0.55), radius: 12, y: 4)

                        Text(unit)
                            .font(Theme.Typography.title(size: 22))
                            .foregroundStyle(Theme.Colors.accent)
                            .padding(.bottom, 6)
                    }

                    if let footnote {
                        Text(footnote)
                            .font(Theme.Typography.caption(size: 12))
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.45, dampingFraction: 0.86), value: footnote)
                    }
                }

                Spacer(minLength: 0)

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Theme.Colors.accentBright, Theme.Colors.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: Theme.Colors.accent.opacity(0.5), radius: 10, y: 4)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .symbolRenderingMode(.hierarchical)
                }
            }
            .padding(Theme.Spacing.large)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 132)
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Theme.Colors.accentBright.opacity(0.7),
                            Theme.Colors.accent.opacity(0.25),
                            Theme.Colors.accent.opacity(0.05),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        }
    }
}

private struct PerformanceStatCard: View {
    enum Style {
        case speed, sprints, sprintDistance, pace

        var accent: Color {
            switch self {
            case .speed: Color(red: 1, green: 0.85, blue: 0.35)
            case .sprints: Theme.Colors.accent
            case .sprintDistance: Color(red: 0.45, green: 0.85, blue: 1)
            case .pace: Theme.Colors.accentBright
            }
        }
    }

    let label: String
    let value: Double?
    let format: AnimatedMetricText.Format
    let unit: String?
    let icon: String
    let style: Style
    let kind: PerformanceMetricKind

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.Colors.surface,
                            Color(red: 0.1, green: 0.1, blue: 0.11),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(style.accent.opacity(0.18))
                            .frame(width: 36, height: 36)
                        Image(systemName: icon)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(style.accent)
                    }
                    Spacer(minLength: 0)
                    if let badge = kind.badge {
                        PerformanceMetricBadge(text: badge, kind: kind)
                    }
                }

                Spacer(minLength: Theme.Spacing.small)

                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    AnimatedMetricText(value: value, format: format)
                        .font(Theme.Typography.metric(size: 40))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .minimumScaleFactor(0.65)
                        .lineLimit(1)

                    if let unit {
                        Text(unit)
                            .font(Theme.Typography.caption(size: 13))
                            .foregroundStyle(style.accent.opacity(0.95))
                            .padding(.bottom, 5)
                    }
                }

                Text(label.uppercased())
                    .font(Theme.Typography.statLabel(size: 9))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .tracking(0.9)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .padding(Theme.Spacing.medium)
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            style.accent.opacity(0.45),
                            Color.white.opacity(0.06),
                            Color.clear,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
}

