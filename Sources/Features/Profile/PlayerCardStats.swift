import Foundation

/// One stat line on the FUT-style card (abbreviation + value).
struct PlayerCardStat: Equatable {
    let abbrev: String
    let value: String
}

/// Aggregates captured session metrics into the six FUT card stats we support.
enum PlayerCardStatsBuilder {
    /// Left column: intensity, top speed, heart rate. Right: sprints, distance, matches.
    static func build(from sessions: [SportSession]) -> (left: [PlayerCardStat], right: [PlayerCardStat]) {
        let matchCount = sessions.count

        let intensities = sessions.compactMap(\.intensity)
        let speeds = sessions.compactMap(\.speedMaxKmh)
        let heartRates = sessions.compactMap(\.hrAvg)
        let totalSprints = sessions.reduce(0) { $0 + $1.sprints }
        let totalKm = sessions.reduce(0.0) { $0 + $1.distanceM } / 1000

        let intValue = intensities.isEmpty ? "—" : "\(Int((intensities.reduce(0, +) / Double(intensities.count)).rounded()))"
        let spdValue = speeds.isEmpty ? "—" : String(format: "%.1f", speeds.reduce(0, +) / Double(speeds.count))
        let hrValue = heartRates.isEmpty ? "—" : "\(heartRates.reduce(0, +) / heartRates.count)"
        let sprValue = matchCount == 0 ? "—" : "\(totalSprints)"
        let kmValue = matchCount == 0 ? "—" : String(format: "%.1f", totalKm)
        let matValue = matchCount == 0 ? "—" : "\(matchCount)"

        let left = [
            PlayerCardStat(abbrev: "INT", value: intValue),
            PlayerCardStat(abbrev: "SPD", value: spdValue),
            PlayerCardStat(abbrev: "HR", value: hrValue),
        ]
        let right = [
            PlayerCardStat(abbrev: "SPR", value: sprValue),
            PlayerCardStat(abbrev: "KM", value: kmValue),
            PlayerCardStat(abbrev: "MAT", value: matValue),
        ]
        return (left, right)
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
