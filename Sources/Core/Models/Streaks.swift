import Foundation

/// Weekly streak (ISO weeks with a match) plus special performance streaks.
struct Streaks: Equatable, Codable, Sendable {
    var currentWeeks: Int
    var bestWeeks: Int
    var special: [SpecialStreak]
}

/// A performance-based streak (current leading run of matches).
struct SpecialStreak: Equatable, Codable, Sendable, Identifiable {
    var kind: String
    var count: Int
    var threshold: Int
    var active: Bool

    var id: String { kind }

    /// Milestones (weeks) that award a "premio".
    static let weekMilestones = [2, 4, 8, 12, 24]
}

extension Streaks {
    /// Highest week milestone reached by the current streak (nil if below the first).
    var currentMilestone: Int? {
        SpecialStreak.weekMilestones.last { currentWeeks >= $0 }
    }

    /// Active special streaks only.
    var activeSpecials: [SpecialStreak] { special.filter(\.active) }
}
