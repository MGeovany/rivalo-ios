import Foundation

/// An achievement badge with the user's progress toward it (V3-F).
struct Badge: Equatable, Codable, Sendable, Identifiable {
    let key: String
    let title: String
    let description: String
    let target: Double
    let current: Double
    let earned: Bool
    let earnedAt: Date?

    var id: String { key }

    /// Progress toward the target, clamped to 0…1.
    var progress: Double {
        guard target > 0 else { return earned ? 1 : 0 }
        return min(current / target, 1)
    }
}

/// Envelope for `GET /v1/badges`.
struct BadgesEnvelope: Equatable, Codable, Sendable {
    var badges: [Badge]
}
