import Foundation

/// Physical averages per position with neutral comparisons (V2-J).
/// `hasEnoughData` is false until the user has ≥3 sessions in each of ≥2 positions.
struct PositionInsights: Equatable, Codable, Sendable {
    var hasEnoughData: Bool
    var positions: [PositionStat]
    var comparisons: [String]?
}

/// Physical averages for one playing position.
struct PositionStat: Equatable, Codable, Sendable, Identifiable {
    var position: String
    var sessionCount: Int
    var avgDistanceM: Double?
    var avgSprints: Double?
    var avgIntensity: Double?
    var avgMatchRating: Double?
    var avgDurationS: Double?

    var id: String { position }
}
