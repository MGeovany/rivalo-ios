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
        case .intensity: "Intensidad (INT)"
        case .speed: "Velocidad máxima (SPD)"
        case .sprints: "Sprints (SPR)"
        case .distance: "Distancia (KM)"
        case .matches: "Partidos (MAT)"
        }
    }

    var explanation: String {
        switch self {
        case .intensity:
            "Tu puntuación de carga física general, basada en frecuencia cardíaca y esfuerzo en todos los partidos registrados."
        case .speed:
            "Tu sprint más rápido en km/h de todos los partidos registrados."
        case .sprints:
            "Total de carreras de alta velocidad por encima del umbral de sprint en todos los partidos."
        case .distance:
            "Total de kilómetros recorridos en todos los partidos registrados."
        case .matches:
            "Número de partidos registrados — esto determina tu nivel y progreso en la tarjeta."
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
        ("AR", "Argentina"), ("AU", "Australia"), ("BE", "Bélgica"), ("BR", "Brasil"),
        ("CA", "Canadá"), ("CL", "Chile"), ("CO", "Colombia"), ("CR", "Costa Rica"),
        ("DE", "Alemania"), ("EC", "Ecuador"), ("ES", "España"), ("FR", "Francia"),
        ("GB", "Inglaterra"), ("GH", "Ghana"), ("HN", "Honduras"), ("IT", "Italia"),
        ("JM", "Jamaica"), ("JP", "Japón"), ("KR", "Corea del Sur"), ("MX", "México"),
        ("NG", "Nigeria"), ("NL", "Países Bajos"), ("NO", "Noruega"), ("PA", "Panamá"),
        ("PE", "Perú"), ("PL", "Polonia"), ("PT", "Portugal"), ("PY", "Paraguay"),
        ("SE", "Suecia"), ("US", "Estados Unidos"), ("UY", "Uruguay"), ("VE", "Venezuela"),
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
