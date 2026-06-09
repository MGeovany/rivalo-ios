import SwiftUI

/// Performance screen title block (orange accent bar + large title + subtitle).
struct PerformanceSectionHeader: View {
    var subtitle = "Tus tendencias de partido de un vistazo"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 12) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.accentBright, Theme.Colors.accent],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 4, height: 36)
                    .shadow(color: Theme.Colors.accent.opacity(0.55), radius: 6, y: 0)

                Text("Rendimiento")
                    .font(Theme.Typography.display(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Theme.Colors.textPrimary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.35), radius: 2, y: 2)
            }

            Text(subtitle)
                .font(Theme.Typography.body(size: 15))
                .foregroundStyle(Theme.Colors.textSecondary)
                .padding(.leading, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rendimiento. \(subtitle)")
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
