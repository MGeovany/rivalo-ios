import SwiftUI

/// Latest match highlight: pitch movement + minimal stats.
struct SessionLastMatchCard: View {
    let session: SportSession
    let meta: SessionMeta
    let onTap: () -> Void

    private var shareText: String {
        SessionActivityGeometry.shareText(session: session, meta: meta)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Button(action: onTap) {
                PitchMapView(session: session, showsInfoCard: false)
            }
            .buttonStyle(.plain)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Latest match")
                        .font(Theme.Typography.statLabel(size: 10))
                        .foregroundStyle(Theme.Colors.accent)
                        .tracking(1)

                    Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(Theme.Typography.button(size: 17))
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text(SessionActivityGeometry.displayLocation(session: session, meta: meta))
                        .font(Theme.Typography.caption(size: 12))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(Theme.Colors.background)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: Theme.Spacing.small
            ) {
                ActivityMetricInline(
                    value: String(format: "%.2f", session.distanceM / 1000),
                    unit: "km",
                    label: "Distance"
                )
                ActivityMetricInline(
                    value: "\(session.durationS / 60)",
                    unit: "min",
                    label: "Time"
                )
                if let hr = session.hrAvg {
                    ActivityMetricInline(value: "\(hr)", unit: "bpm", label: "Avg HR")
                }
                if let intensity = session.intensity {
                    ActivityMetricInline(
                        value: String(format: "%.0f", intensity),
                        unit: nil,
                        label: "Intensity"
                    )
                }
            }
        }
        .padding(Theme.Spacing.medium)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }
}
