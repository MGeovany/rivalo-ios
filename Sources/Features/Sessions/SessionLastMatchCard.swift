import SwiftUI

/// Latest match highlight: pitch movement + key stats.
struct SessionLastMatchCard: View {
    let session: SportSession
    let meta: SessionMeta
    let onTap: () -> Void

    private var shareText: String {
        SessionActivityGeometry.shareText(session: session, meta: meta)
    }

    private var distanceText: String {
        let km = session.distanceM / 1000
        return km >= 10 ? String(format: "%.1f", km) : String(format: "%.2f", km)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            mapSection

            VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                headerSection
                statsGrid
                detailsFooter
            }
            .padding(Theme.Spacing.large)
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay { cardBorder }
    }

    // MARK: - Map

    private var mapSection: some View {
        Button(action: onTap) {
            PitchMapView(session: session, showsInfoCard: false, embeddedInCard: true)
                .padding(Theme.Spacing.medium)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.08, green: 0.09, blue: 0.11),
                            Color(red: 0.05, green: 0.06, blue: 0.07),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.medium) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Último partido")
                    .font(Theme.Typography.statLabel(size: 10))
                    .foregroundStyle(Theme.Colors.accentBright)
                    .tracking(1.2)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.Colors.accent.opacity(0.16))
                    .clipShape(Capsule())

                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(Theme.Typography.title(size: 20))
                    .foregroundStyle(Theme.Colors.textPrimary)

                HStack(spacing: 6) {
                    Image(systemName: session.source == "watch" ? "applewatch" : "hand.tap.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text(SessionActivityGeometry.displayLocation(session: session, meta: meta))
                        .lineLimit(1)
                }
                .font(Theme.Typography.caption(size: 12))
                .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer(minLength: 0)

            ShareLink(item: shareText) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Theme.Colors.accentBright, Theme.Colors.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .shadow(color: Theme.Colors.accent.opacity(0.35), radius: 8, y: 3)

                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.black.opacity(0.85))
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Stats

    private var statsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: Theme.Spacing.medium),
                GridItem(.flexible(), spacing: Theme.Spacing.medium),
            ],
            spacing: Theme.Spacing.medium
        ) {
            LastMatchMetricTile(
                icon: "figure.run",
                accent: Theme.Colors.accent,
                value: distanceText,
                unit: "km",
                label: "Distancia"
            )
            LastMatchMetricTile(
                icon: "clock.fill",
                accent: Theme.Colors.accentBright,
                value: "\(session.durationS / 60)",
                unit: "min",
                label: "Tiempo"
            )
            if let hr = session.hrAvg {
                LastMatchMetricTile(
                    icon: "heart.fill",
                    accent: Color(red: 1, green: 0.45, blue: 0.55),
                    value: "\(hr)",
                    unit: "bpm",
                    label: "FC media"
                )
            }
            if let intensity = session.intensity {
                LastMatchMetricTile(
                    icon: "flame.fill",
                    accent: Color(red: 1, green: 0.75, blue: 0.25),
                    value: String(format: "%.0f", intensity),
                    unit: nil,
                    label: "Intensidad"
                )
            }
        }
    }

    // MARK: - Footer

    private var detailsFooter: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Text("Ver detalles del partido")
                    .font(Theme.Typography.caption(size: 13))
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(Theme.Colors.textSecondary)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Chrome

    private var cardBackground: some View {
        LinearGradient(
            colors: [
                Theme.Colors.surface,
                Color(red: 0.09, green: 0.09, blue: 0.10),
                Theme.Colors.background,
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 22)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Theme.Colors.accentBright.opacity(0.55),
                        Theme.Colors.accent.opacity(0.2),
                        Color.white.opacity(0.05),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
}

// MARK: - Metric tile

private struct LastMatchMetricTile: View {
    let icon: String
    let accent: Color
    let value: String
    let unit: String?
    let label: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16)
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

            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(accent.opacity(0.16))
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(accent)
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(Theme.Typography.metric(size: 26))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .layoutPriority(1)

                    if let unit {
                        Text(unit)
                            .font(Theme.Typography.caption(size: 12))
                            .foregroundStyle(accent.opacity(0.95))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }

                Text(label.uppercased())
                    .font(Theme.Typography.statLabel(size: 9))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .tracking(0.8)
                    .lineLimit(1)
            }
            .padding(Theme.Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 108)
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [accent.opacity(0.35), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
}
