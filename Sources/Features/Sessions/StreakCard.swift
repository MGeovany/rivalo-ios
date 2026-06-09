import SwiftUI

/// Home card: current weekly streak, best streak, the highest milestone award
/// reached, and chips for any active special performance streaks.
struct StreakCard: View {
    let streaks: Streaks

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.small) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.Colors.accent)
                Text("\(streaks.currentWeeks)")
                    .font(Theme.Typography.metric(size: 34))
                    .monospacedDigit()
                Text(streaks.currentWeeks == 1 ? "semana seguida" : "semanas seguidas")
                    .font(Theme.Typography.body(size: 15))
                    .foregroundStyle(Theme.Colors.textSecondary)
                Spacer()
                if streaks.bestWeeks > 0 {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(streaks.bestWeeks)")
                            .font(Theme.Typography.metric(size: 18))
                            .monospacedDigit()
                        Text("mejor")
                            .font(Theme.Typography.caption(size: 10))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }

            if let milestone = streaks.currentMilestone {
                HStack(spacing: 6) {
                    Image(systemName: "rosette")
                        .font(.system(size: 13, weight: .bold))
                    Text("\(milestone) semanas — logro desbloqueado")
                        .font(Theme.Typography.caption(size: 12))
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.Colors.accent)
                .clipShape(Capsule())
            }

            if !streaks.activeSpecials.isEmpty {
                HStack(spacing: Theme.Spacing.small) {
                    ForEach(streaks.activeSpecials) { s in
                        specialChip(s)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(Theme.Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private func specialChip(_ s: SpecialStreak) -> some View {
        HStack(spacing: 5) {
            Image(systemName: Self.icon(for: s.kind))
                .font(.system(size: 11, weight: .semibold))
            Text("\(Self.label(for: s.kind)) ×\(s.count)")
                .font(Theme.Typography.caption(size: 11))
        }
        .foregroundStyle(Theme.Colors.accent)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Theme.Colors.accent.opacity(0.14))
        .clipShape(Capsule())
    }

    private static func icon(for kind: String) -> String {
        switch kind {
        case "sprints": return "hare.fill"
        case "rating_improving": return "chart.line.uptrend.xyaxis"
        case "fatigue_controlled": return "bolt.heart.fill"
        default: return "sparkles"
        }
    }

    private static func label(for kind: String) -> String {
        switch kind {
        case "sprints": return "Racha de sprints"
        case "rating_improving": return "Valoración al alza"
        case "fatigue_controlled": return "Control de fatiga"
        default: return kind
        }
    }
}
