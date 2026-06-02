import Foundation

enum PlayerCardBadge: Equatable {
    case newPR
    case mostImproved

    var label: String {
        switch self {
        case .newPR: "NEW PR"
        case .mostImproved: "MOST IMPROVED"
        }
    }
}

/// Aggregated metrics shown on the shareable player progress card.
struct PlayerCardMetrics: Equatable {
    let matchCount: Int
    let rank: PlayerCardRank
    let tierProgress: Int
    let physicalRating: Int?
    let topSpeedKmh: Double?
    let avgSprints: Int?
    let avgDistanceKm: Double?
    /// Average high-intensity drop across structured sessions (negative = fatigue).
    let fatigueDropPct: Double?
    let badge: PlayerCardBadge?
}

enum PlayerCardStatsBuilder {
    static func build(from sessions: [SportSession]) -> PlayerCardMetrics {
        guard !sessions.isEmpty else {
            return PlayerCardMetrics(
                matchCount: 0,
                rank: .unranked,
                tierProgress: 0,
                physicalRating: nil,
                topSpeedKmh: nil,
                avgSprints: nil,
                avgDistanceKm: nil,
                fatigueDropPct: nil,
                badge: nil
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

        let fatigueValues = sessions.compactMap(\.fatigueDrop?.highIntensityPctChange)
        let fatigueDropPct = fatigueValues.isEmpty
            ? nil
            : fatigueValues.reduce(0, +) / Double(fatigueValues.count)

        return PlayerCardMetrics(
            matchCount: matchCount,
            rank: rank,
            tierProgress: tierProgress,
            physicalRating: physicalRating,
            topSpeedKmh: snapshot.topSpeedKmh,
            avgSprints: snapshot.avgSprints,
            avgDistanceKm: snapshot.avgKmPerMatch,
            fatigueDropPct: fatigueDropPct,
            badge: detectBadge(from: sessions)
        )
    }

    private static func detectBadge(from sessions: [SportSession]) -> PlayerCardBadge? {
        let sorted = sessions.sorted { $0.startedAt > $1.startedAt }
        guard let latest = sorted.first, sorted.count >= 2 else { return nil }
        let prior = Array(sorted.dropFirst())

        if let speed = latest.speedMaxKmh {
            let priorMax = prior.compactMap(\.speedMaxKmh).max() ?? 0
            if speed > priorMax { return .newPR }
        }
        if latest.distanceM > (prior.map(\.distanceM).max() ?? 0) { return .newPR }
        if latest.sprints > (prior.map(\.sprints).max() ?? 0) { return .newPR }

        if let latestIntensity = latest.intensity {
            let priorIntensities = prior.compactMap(\.intensity)
            guard !priorIntensities.isEmpty else { return nil }
            let average = priorIntensities.reduce(0, +) / Double(priorIntensities.count)
            if latestIntensity - average >= 8 { return .mostImproved }
        }

        return nil
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
