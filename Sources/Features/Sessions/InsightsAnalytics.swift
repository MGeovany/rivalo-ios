import Foundation

/// Client-side aggregates for the Insights tab (sessions + API breakdowns).
enum InsightsAnalytics {
    static let minMatchesForTrends = 3
    static let minMatchesForStrongCallouts = 5

    struct MatchPoint: Equatable, Identifiable {
        let id: String
        let label: String
        let value: Double
        let isNewPR: Bool
    }

    struct TrendCallout: Equatable {
        let text: String
        let tone: Tone

        enum Tone: Equatable {
            case up
            case down
            case neutral
        }
    }

    struct FatigueSummary: Equatable {
        let firstHalfAvgMinutes: Double
        let secondHalfAvgMinutes: Double
        let dropPercent: Double
        let sessionCount: Int
    }

    struct ConsistencySummary: Equatable {
        let score: Int
        let detail: String
    }

    struct PerformanceRow: Equatable, Identifiable {
        let value: String
        let avgScore: Double
        let matchCount: Int

        var id: String { value }
    }

    // MARK: - Trends

    static func ratingTrend(
        sessions: [SportSession],
        limit: Int = 8
    ) -> (points: [MatchPoint], callout: TrendCallout?) {
        let rated = sessions
            .filter { $0.matchRating != nil }
            .sorted { $0.startedAt < $1.startedAt }
            .suffix(limit)
        let points = rated.map { session in
            MatchPoint(
                id: session.id,
                label: shortDate(session.startedAt),
                value: session.matchRating ?? 0,
                isNewPR: false
            )
        }
        let callout = ratingCallout(from: Array(rated), totalCount: sessions.count)
        return (points, callout)
    }

    static func sprintsTrend(sessions: [SportSession], limit: Int = 8) -> [MatchPoint] {
        sessions
            .filter { $0.sprints > 0 }
            .sorted { $0.startedAt < $1.startedAt }
            .suffix(limit)
            .map { session in
                MatchPoint(
                    id: session.id,
                    label: shortDate(session.startedAt),
                    value: Double(session.sprints),
                    isNewPR: false
                )
            }
    }

    static func topSpeedTrend(
        sessions: [SportSession],
        speedRecordSessionId: String?,
        limit: Int = 8
    ) -> [MatchPoint] {
        let chronological = sessions
            .compactMap { session -> (SportSession, Double)? in
                guard let speed = session.speedMaxKmh, speed > 0 else { return nil }
                return (session, speed)
            }
            .sorted { $0.0.startedAt < $1.0.startedAt }

        var runningMax = 0.0
        var flags: [String: Bool] = [:]
        for (session, speed) in chronological {
            let isPR = speed > runningMax
            if isPR { runningMax = speed }
            flags[session.id] = isPR
        }

        return chronological
            .suffix(limit)
            .map { session, speed in
                let isGlobalPR = speedRecordSessionId == session.id
                return MatchPoint(
                    id: session.id,
                    label: shortDate(session.startedAt),
                    value: speed,
                    isNewPR: flags[session.id] == true || isGlobalPR
                )
            }
    }

    // MARK: - Fatigue

    static func fatigueSummary(from sessions: [SportSession]) -> FatigueSummary? {
        let withDrop = sessions.compactMap(\.fatigueDrop)
        guard !withDrop.isEmpty else { return nil }

        let firstKm = withDrop.map { Double($0.firstHalf.highIntensityS) / 60.0 }
        let secondKm = withDrop.map { Double($0.secondHalf.highIntensityS) / 60.0 }
        let avgFirst = firstKm.reduce(0, +) / Double(firstKm.count)
        let avgSecond = secondKm.reduce(0, +) / Double(secondKm.count)
        let drop = avgFirst > 0 ? ((avgFirst - avgSecond) / avgFirst) * 100 : 0

        return FatigueSummary(
            firstHalfAvgMinutes: avgFirst,
            secondHalfAvgMinutes: avgSecond,
            dropPercent: max(0, drop),
            sessionCount: withDrop.count
        )
    }

    // MARK: - Performance rows

    static let matchTypeOrder = ["5-a-side", "7-a-side", "9-a-side", "11-a-side", "Other"]

    static func performanceRows(
        from groups: [ContextGroup],
        preferredOrder: [String]? = nil
    ) -> [PerformanceRow] {
        let rows = groups.compactMap { group -> PerformanceRow? in
            guard let score = group.avgMatchRating, group.count > 0 else { return nil }
            return PerformanceRow(value: group.value, avgScore: score, matchCount: group.count)
        }
        guard let order = preferredOrder else {
            return rows.sorted { $0.avgScore > $1.avgScore }
        }
        return rows.sorted { lhs, rhs in
            let li = order.firstIndex(of: lhs.value) ?? order.count
            let ri = order.firstIndex(of: rhs.value) ?? order.count
            if li != ri { return li < ri }
            return lhs.avgScore > rhs.avgScore
        }
    }

    // MARK: - Consistency

    static func consistency(
        sessions: [SportSession],
        totalCount: Int
    ) -> ConsistencySummary? {
        let ratings = sessions.compactMap(\.matchRating)
        guard ratings.count >= minMatchesForTrends else { return nil }

        let mean = ratings.reduce(0, +) / Double(ratings.count)
        guard mean > 0 else { return nil }

        let variance = ratings.reduce(0) { $0 + pow($1 - mean, 2) } / Double(ratings.count)
        let stdDev = sqrt(variance)
        let cv = (stdDev / mean) * 100
        let score = Int(max(0, min(100, 100 - cv)).rounded())

        let detail: String
        if totalCount < minMatchesForStrongCallouts {
            detail = "Based on \(ratings.count) rated matches — log more for a clearer read."
        } else if score >= 75 {
            detail = "Your match ratings stay close from game to game."
        } else if score >= 50 {
            detail = "Some swing between matches — normal as you adapt."
        } else {
            detail = "Ratings vary more — form may depend on match context."
        }

        return ConsistencySummary(score: score, detail: detail)
    }

    // MARK: - Helpers

    private static func ratingCallout(from rated: [SportSession], totalCount: Int) -> TrendCallout? {
        guard rated.count >= 4 else {
            if totalCount < minMatchesForStrongCallouts, rated.count >= 2 {
                return TrendCallout(text: "Early trend — a few more matches help.", tone: .neutral)
            }
            return nil
        }

        let recent = Array(rated.suffix(3))
        let prior = Array(rated.dropLast(3).suffix(3))
        guard prior.count >= 2 else { return nil }

        let recentAvg = recent.compactMap(\.matchRating).reduce(0, +) / Double(recent.count)
        let priorAvg = prior.compactMap(\.matchRating).reduce(0, +) / Double(prior.count)
        let delta = recentAvg - priorAvg

        if totalCount < minMatchesForStrongCallouts {
            return TrendCallout(text: "Early sample — trends may shift.", tone: .neutral)
        }
        if delta >= 4 {
            return TrendCallout(
                text: String(format: "Up %.0f pts in recent matches", delta),
                tone: .up
            )
        }
        if delta <= -4 {
            return TrendCallout(
                text: String(format: "Down %.0f pts lately", abs(delta)),
                tone: .down
            )
        }
        return TrendCallout(text: "Holding steady recently", tone: .neutral)
    }

    private static func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated))
    }

    static func structuredSessionIds(from sessions: [SportSession], limit: Int = 6) -> [String] {
        sessions
            .filter { $0.mode == "structured" || $0.halftimeOffsetS != nil }
            .sorted { $0.startedAt > $1.startedAt }
            .prefix(limit)
            .map(\.id)
    }
}
