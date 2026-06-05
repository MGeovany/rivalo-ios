import Foundation

struct SessionInsights: Equatable, Codable, Sendable {
    var totals: StatsTotals
    var averages: StatsAverages
    var byMatchType: [ContextGroup]
    var bySurface: [ContextGroup]
    var byPosition: [ContextGroup]
    /// Rule-based, explainable statements; nil/empty below the backend threshold (≥5 sessions).
    var insights: [Insight]?

    // The backend may return null for group arrays when there is no data yet.
    // Custom decoder falls back to [] instead of throwing DecodingError.
    private enum CodingKeys: String, CodingKey {
        case totals, averages, byMatchType, bySurface, byPosition, insights
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        totals = try c.decode(StatsTotals.self, forKey: .totals)
        averages = try c.decode(StatsAverages.self, forKey: .averages)
        byMatchType = (try? c.decode([ContextGroup].self, forKey: .byMatchType)) ?? []
        bySurface = (try? c.decode([ContextGroup].self, forKey: .bySurface)) ?? []
        byPosition = (try? c.decode([ContextGroup].self, forKey: .byPosition)) ?? []
        insights = try? c.decode([Insight].self, forKey: .insights)
    }
}

/// One explainable, rule-based post-match insight comparing a session to history.
struct MatchInsight: Equatable, Codable, Sendable, Identifiable {
    var kind: String
    var title: String
    var message: String

    var id: String { kind }
}

/// One explainable, rule-based observation, computed server-side.
struct Insight: Equatable, Codable, Sendable, Identifiable {
    var kind: String
    var title: String
    var detail: String

    var id: String { kind }
}

struct StatsTotals: Equatable, Codable, Sendable {
    var sessionCount: Int
    var totalDistanceM: Double
    var totalDurationS: Int
    var totalCalories: Double?
}

struct StatsAverages: Equatable, Codable, Sendable {
    var distancePerMatch: Double?
    var durationPerMatch: Double?
    var sprintsPerMatch: Double?
    var intensity: Double?
    var matchRating: Double?
}

struct ContextGroup: Equatable, Codable, Sendable, Identifiable {
    var value: String
    var count: Int
    var avgMatchRating: Double?
    var avgDistance: Double?
    var avgDurationS: Double?
    var avgIntensity: Double?

    var id: String { value }
}
