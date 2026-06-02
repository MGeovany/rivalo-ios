import Foundation

struct Rivalry: Identifiable, Equatable, Decodable {
    let opponent: String
    let matchCount: Int
    let wins: Int
    let draws: Int
    let losses: Int
    let lastPlayedAt: Date
    let avgRating: Double?
    let avgDistanceM: Double?
    let avgSprints: Double?

    var id: String { opponent }

    var totalDecided: Int { wins + losses }
    var winRate: Double? {
        totalDecided > 0 ? Double(wins) / Double(totalDecided) * 100 : nil
    }
}
