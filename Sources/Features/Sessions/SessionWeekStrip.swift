import SwiftUI

/// Strava-style week row: which days had a match this week.
struct SessionWeekStrip: View {
    let sessions: [SportSession]
    let referenceDate: Date

    private var calendar: Calendar { Calendar.current }

    private var weekDays: [Date] {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: referenceDate) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
    }

    private var matchDays: Set<DateComponents> {
        Set(sessions.map { calendar.dateComponents([.yearForWeekOfYear, .weekOfYear, .weekday], from: $0.startedAt) })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            HStack {
                Text(weekTitle)
                    .font(Theme.Typography.button(size: 15))
                    .foregroundStyle(Theme.Colors.textPrimary)
                Spacer()
                Text("\(sessionsThisWeek) \(sessionsThisWeek == 1 ? "partido" : "partidos")")
                    .font(Theme.Typography.caption(size: 12))
                    .foregroundStyle(Theme.Colors.accent)
            }

            HStack(spacing: 0) {
                ForEach(weekDays, id: \.timeIntervalSince1970) { day in
                    dayCell(day)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, Theme.Spacing.medium)
            .padding(.horizontal, Theme.Spacing.small)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Theme.Colors.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: Theme.Radius.card)
                            .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                    }
            )
        }
    }

    private var weekTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        guard let first = weekDays.first, let last = weekDays.last else { return "This week" }
        return "This week · \(formatter.string(from: first)) – \(formatter.string(from: last))"
    }

    private var sessionsThisWeek: Int {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: referenceDate) else { return 0 }
        return sessions.filter { $0.startedAt >= interval.start && $0.startedAt < interval.end }.count
    }

    private func dayCell(_ day: Date) -> some View {
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear, .weekday], from: day)
        let hasMatch = matchDays.contains(comps)
        let isToday = calendar.isDateInToday(day)
        let symbol = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: day) - 1]

        return VStack(spacing: 8) {
            Text(symbol.prefix(1).uppercased())
                .font(Theme.Typography.statLabel(size: 11))
                .foregroundStyle(isToday ? Theme.Colors.accent : Theme.Colors.textSecondary)

            ZStack {
                Circle()
                    .strokeBorder(
                        hasMatch ? Theme.Colors.accent : Theme.Colors.textSecondary.opacity(0.25),
                        lineWidth: hasMatch ? 0 : 2
                    )
                    .background(
                        Circle()
                            .fill(hasMatch ? Theme.Colors.accent : Color.clear)
                    )
                    .frame(width: 36, height: 36)

                if hasMatch {
                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.black)
                } else {
                    Text("\(calendar.component(.day, from: day))")
                        .font(Theme.Typography.caption(size: 13))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }

            if isToday {
                Circle()
                    .fill(Theme.Colors.accentBright)
                    .frame(width: 4, height: 4)
            } else {
                Color.clear.frame(width: 4, height: 4)
            }
        }
    }
}
