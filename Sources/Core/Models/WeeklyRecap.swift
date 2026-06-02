import Foundation

/// Current-week summary plus the change vs the previous week (V3-E).
struct WeeklyRecap: Equatable, Codable, Sendable {
    var current: WeekSummary
    var previous: WeekSummary
    var distanceDeltaPct: Double?
    var ratingDeltaPct: Double?
}

/// Aggregated matches of a single ISO week.
struct WeekSummary: Equatable, Codable, Sendable {
    var matchCount: Int
    var totalDistanceM: Double
    var totalSprints: Int
    var avgRating: Double?
    var bestSessionId: String?
}
