import Foundation

/// Dynamic inputs for the shareable player card.
struct PlayerCardContent: Equatable {
    let name: String
    let countryCode: String
    let position: String
    let rating: Int?
    let tier: PlayerCardRank
    let matches: Int
    let distanceKm: Double
    let topSpeed: Double?
    let sprints: Int
    let intensity: Int?

    var positionAbbrev: String {
        ProfileFormatting.positionAbbreviation(position)
    }

    var ratingText: String {
        rating.map { "\($0)" } ?? "—"
    }

    var intensityText: String {
        intensity.map { "\($0)" } ?? "—"
    }

    var topSpeedText: String {
        topSpeed.map { String(format: "%.1f", $0) } ?? "—"
    }

    var distanceText: String {
        String(format: "%.1f", distanceKm)
    }

    var sprintsText: String {
        "\(sprints)"
    }

    var matchesText: String {
        "\(matches)"
    }

    var tierLabel: String {
        tier.displayName.uppercased()
    }
}

extension PlayerCardContent {
    /// Builds card content from aggregated session metrics.
    static func from(metrics: PlayerCardMetrics, name: String, countryCode: String, position: String?) -> PlayerCardContent {
        let positionText = position?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let spd = Double(metrics.displayStats.spdValue).flatMap { $0 > 0 ? $0 : nil }
        let km = Double(metrics.displayStats.kmValue) ?? 0
        let intensity = Int(metrics.displayStats.intValue).flatMap { $0 > 0 ? $0 : nil }

        return PlayerCardContent(
            name: name,
            countryCode: countryCode,
            position: positionText.isEmpty ? "—" : positionText,
            rating: metrics.physicalRating,
            tier: metrics.rank,
            matches: metrics.matchCount,
            distanceKm: km,
            topSpeed: spd,
            sprints: Int(metrics.displayStats.sprValue) ?? 0,
            intensity: intensity
        )
    }
}

extension PlayerCardModel {
    var content: PlayerCardContent {
        PlayerCardContent(
            name: displayName,
            countryCode: countryCode,
            position: position ?? "—",
            rating: physicalRating,
            tier: rank,
            matches: matchCount,
            distanceKm: Double(displayStats.kmValue) ?? 0,
            topSpeed: Double(displayStats.spdValue),
            sprints: Int(displayStats.sprValue) ?? 0,
            intensity: Int(displayStats.intValue)
        )
    }
}
