import SwiftUI

/// Performance screen title block (orange bar + subtitle).
struct PerformanceSectionHeader: View {
    var subtitle = "Your match trends at a glance"

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.accentBright, Theme.Colors.accent],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 4, height: 28)

                Text("Performance")
                    .font(Theme.Typography.title(size: 34))
                    .foregroundStyle(Theme.Colors.textPrimary)
            }

            Text(subtitle)
                .font(Theme.Typography.body(size: 15))
                .foregroundStyle(Theme.Colors.textSecondary)
                .padding(.leading, 14)
        }
    }
}

/// Compact stat: value + unit stay on one line.
struct ActivityMetricInline: View {
    let value: String
    let unit: String?
    let label: String
    var valueSize: CGFloat = 20

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(Theme.Typography.metric(size: valueSize))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .layoutPriority(1)

                if let unit {
                    Text(unit)
                        .font(Theme.Typography.caption(size: 11))
                        .foregroundStyle(Theme.Colors.accent)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }

            Text(label.uppercased())
                .font(Theme.Typography.statLabel(size: 9))
                .foregroundStyle(Theme.Colors.textSecondary)
                .tracking(0.6)
                .lineLimit(1)
        }
    }
}
