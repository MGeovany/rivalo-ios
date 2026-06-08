import SwiftUI

/// Compact context for the Record tab: last setup + optional stats from the latest session.
struct RecordLastContextCard: View {
    let setup: iOSMatchSetup
    let session: SportSession?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            headerRow
            formatRow

            if let locationLine {
                Label {
                    Text(locationLine)
                        .font(Theme.Typography.caption(size: 13))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .lineLimit(2)
                } icon: {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textSecondary.opacity(0.85))
                }
                .labelStyle(.titleAndIcon)
            }

            if let session {
                statsRow(for: session)
            } else {
                Text("Your Watch reuses this setup when you record.")
                    .font(Theme.Typography.caption(size: 12))
                    .foregroundStyle(Theme.Colors.textSecondary.opacity(0.9))
            }
        }
        .padding(Theme.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.surface.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        }
    }

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Last match")
                .font(Theme.Typography.statLabel(size: 10))
                .foregroundStyle(Theme.Colors.textSecondary)
                .tracking(1)

            Spacer(minLength: Theme.Spacing.small)

            if let session {
                Text(session.startedAt.formatted(.relative(presentation: .named)))
                    .font(Theme.Typography.caption(size: 12))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
    }

    private var formatRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(setup.matchType)
                .font(Theme.Typography.button(size: 17))
                .foregroundStyle(Theme.Colors.textPrimary)

            Text("·")
                .foregroundStyle(Theme.Colors.textSecondary.opacity(0.5))

            Text(setup.mode.capitalized)
                .font(Theme.Typography.body(size: 15))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    private var locationLine: String? {
        var parts: [String] = []
        if let pitch = setup.pitchName?.trimmingCharacters(in: .whitespacesAndNewlines), !pitch.isEmpty {
            parts.append(pitch)
        }
        let surface = setup.surface.trimmingCharacters(in: .whitespacesAndNewlines)
        if !surface.isEmpty {
            parts.append(surface)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private func statsRow(for session: SportSession) -> some View {
        HStack(spacing: 0) {
            statCell(
                value: distanceValue(session),
                unit: "km",
                label: "Distance"
            )
            statDivider
            statCell(
                value: "\(session.durationS / 60)",
                unit: "min",
                label: "Time"
            )
            if let intensity = session.intensity {
                statDivider
                statCell(
                    value: String(format: "%.0f", intensity),
                    unit: nil,
                    label: "Intensity"
                )
            }
        }
        .padding(.top, 4)
    }

    private func distanceValue(_ session: SportSession) -> String {
        let km = session.distanceM / 1000
        return km >= 10 ? String(format: "%.1f", km) : String(format: "%.2f", km)
    }

    private func statCell(value: String, unit: String?, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(Theme.Typography.metric(size: 22))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if let unit {
                    Text(unit)
                        .font(Theme.Typography.caption(size: 11))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }

            Text(label.uppercased())
                .font(Theme.Typography.statLabel(size: 9))
                .foregroundStyle(Theme.Colors.textSecondary)
                .tracking(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(width: 1, height: 36)
            .padding(.horizontal, Theme.Spacing.small)
    }
}

#Preview {
    RecordLastContextCard(
        setup: iOSMatchSetup(
            mode: "quick",
            matchType: "11-a-side",
            surface: "Artificial turf",
            pitchId: nil,
            pitchName: "11-a-side Complex",
            pitchLatitude: nil,
            pitchLongitude: nil,
            competition: nil
        ),
        session: nil
    )
    .padding()
    .background(Theme.Colors.background)
}
