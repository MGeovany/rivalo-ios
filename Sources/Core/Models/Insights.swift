import Foundation

struct SessionInsights: Equatable, Codable, Sendable {
    var totals: StatsTotals
    var averages: StatsAverages
    var byMatchType: [ContextGroup]
    var bySurface: [ContextGroup]
    var byPosition: [ContextGroup]
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
