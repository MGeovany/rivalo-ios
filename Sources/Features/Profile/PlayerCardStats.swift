import Foundation

/// Card stat abbreviations (INT / SPD / SPR / KM / MAT) with tap-to-explain copy.
enum PlayerCardStatKind: String, CaseIterable, Identifiable {
    case intensity
    case speed
    case sprints
    case distance
    case matches

    var id: String { rawValue }

    var abbrev: String {
        switch self {
        case .intensity: "INT"
        case .speed: "SPD"
        case .sprints: "SPR"
        case .distance: "KM"
        case .matches: "MAT"
        }
    }

    var title: String {
        switch self {
        case .intensity: "Intensity (INT)"
        case .speed: "Top speed (SPD)"
        case .sprints: "Sprints (SPR)"
        case .distance: "Distance (KM)"
        case .matches: "Matches (MAT)"
        }
    }

    var explanation: String {
        switch self {
        case .intensity:
            "Your overall physical load score, based on heart rate and effort across recorded matches."
        case .speed:
            "Your fastest sprint in km/h from all recorded matches."
        case .sprints:
            "Total high-speed runs above the sprint threshold across all matches."
        case .distance:
            "Total kilometers covered across all recorded matches."
        case .matches:
            "Number of matches logged — this drives your card tier and rank progress."
        }
    }
}

/// FUT card stat values shown on the shareable card (INT / SPD / SPR / KM / MAT).
struct PlayerCardDisplayStats: Equatable {
    let intValue: String
    let spdValue: String
    let sprValue: String
    let kmValue: String
    let matValue: String

    static let empty = PlayerCardDisplayStats(
        intValue: "—",
        spdValue: "—",
        sprValue: "—",
        kmValue: "—",
        matValue: "—"
    )
}

/// Aggregated metrics shown on the shareable player progress card.
struct PlayerCardMetrics: Equatable {
    let matchCount: Int
    let rank: PlayerCardRank
    let tierProgress: Int
    let physicalRating: Int?
    let displayStats: PlayerCardDisplayStats
}

enum PlayerCardStatsBuilder {
    static func build(from sessions: [SportSession]) -> PlayerCardMetrics {
        guard !sessions.isEmpty else {
            return PlayerCardMetrics(
                matchCount: 0,
                rank: .unranked,
                tierProgress: 0,
                physicalRating: nil,
                displayStats: .empty
            )
        }

        let matchCount = sessions.count
        let rank = PlayerCardRank.resolve(matchCount: matchCount)
        let tierProgress = PlayerCardRank.tierProgress(matchCount: matchCount)

        let snapshot = PerformanceSnapshot.build(from: sessions)
        let intensities = sessions.compactMap(\.intensity)
        let physicalRating: Int? = intensities.isEmpty
            ? nil
            : Int((intensities.reduce(0, +) / Double(intensities.count)).rounded())

        let totalSprints = sessions.reduce(0) { $0 + $1.sprints }
        let totalKm = sessions.reduce(0.0) { $0 + $1.distanceM } / 1000

        let displayStats = PlayerCardDisplayStats(
            intValue: physicalRating.map { "\($0)" } ?? "—",
            spdValue: snapshot.topSpeedKmh.map { String(format: "%.1f", $0) } ?? "—",
            sprValue: "\(totalSprints)",
            kmValue: String(format: "%.1f", totalKm),
            matValue: "\(matchCount)"
        )

        return PlayerCardMetrics(
            matchCount: matchCount,
            rank: rank,
            tierProgress: tierProgress,
            physicalRating: physicalRating,
            displayStats: displayStats
        )
    }
}

/// ISO country codes for the nationality flag on the card.
enum FootballCountry {
    static let options: [(code: String, name: String)] = [
        ("AR", "Argentina"), ("AU", "Australia"), ("BE", "Belgium"), ("BR", "Brazil"),
        ("CA", "Canada"), ("CL", "Chile"), ("CO", "Colombia"), ("CR", "Costa Rica"),
        ("DE", "Germany"), ("EC", "Ecuador"), ("ES", "Spain"), ("FR", "France"),
        ("GB", "England"), ("GH", "Ghana"), ("HN", "Honduras"), ("IT", "Italy"),
        ("JM", "Jamaica"), ("JP", "Japan"), ("KR", "South Korea"), ("MX", "Mexico"),
        ("NG", "Nigeria"), ("NL", "Netherlands"), ("NO", "Norway"), ("PA", "Panama"),
        ("PE", "Peru"), ("PL", "Poland"), ("PT", "Portugal"), ("PY", "Paraguay"),
        ("SE", "Sweden"), ("US", "United States"), ("UY", "Uruguay"), ("VE", "Venezuela"),
    ]

    static func name(for code: String) -> String {
        let upper = code.uppercased()
        return options.first { $0.code == upper }?.name ?? upper
    }

    static func flagEmoji(for code: String) -> String {
        let upper = code.uppercased()
        guard upper.count == 2 else { return "🏳️" }
        let scalars = upper.unicodeScalars.compactMap { UnicodeScalar(127_397 + $0.value) }
        return String(String.UnicodeScalarView(scalars))
    }
}
