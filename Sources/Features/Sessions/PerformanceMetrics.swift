import Foundation

/// Time window for Performance dashboard aggregates.
enum PerformancePeriod: String, CaseIterable, Equatable, Identifiable {
    case allTime = "Todo el tiempo"
    case thisWeek = "Esta semana"
    case thisMonth = "Este mes"
    case lastFive = "Últimos 5 partidos"

    var id: String { rawValue }

    func filter(_ sessions: [SportSession], reference: Date = Date()) -> [SportSession] {
        let sorted = sessions.sorted { $0.startedAt > $1.startedAt }
        let calendar = Calendar.current
        switch self {
        case .thisWeek:
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: reference) else { return [] }
            return sorted.filter { $0.startedAt >= interval.start && $0.startedAt < interval.end }
        case .thisMonth:
            guard let interval = calendar.dateInterval(of: .month, for: reference) else { return [] }
            return sorted.filter { $0.startedAt >= interval.start && $0.startedAt < interval.end }
        case .lastFive:
            return Array(sorted.prefix(5))
        case .allTime:
            return sorted
        }
    }
}

/// Aggregated metrics for one performance period.
struct PerformanceSnapshot: Equatable {
    let sessionCount: Int
    let totalDistanceKm: Double
    let topSpeedKmh: Double?
    let avgSprints: Int?
    let avgSprintDistanceKm: Double?
    let avgKmPerMatch: Double?

    static let empty = PerformanceSnapshot(
        sessionCount: 0,
        totalDistanceKm: 0,
        topSpeedKmh: nil,
        avgSprints: nil,
        avgSprintDistanceKm: nil,
        avgKmPerMatch: nil
    )

    static func build(from sessions: [SportSession]) -> PerformanceSnapshot {
        guard !sessions.isEmpty else { return .empty }

        let totalKm = sessions.reduce(0) { $0 + $1.distanceM } / 1000
        let topSpeed = sessions.compactMap(\.speedMaxKmh).max()
        let avgSprints = sessions.reduce(0) { $0 + $1.sprints } / sessions.count
        let sprintDistances = sessions.map(\.sprintDistanceM)
        let avgSprintKm = sprintDistances.reduce(0, +) / Double(sessions.count) / 1000

        return PerformanceSnapshot(
            sessionCount: sessions.count,
            totalDistanceKm: totalKm,
            topSpeedKmh: topSpeed,
            avgSprints: avgSprints,
            avgSprintDistanceKm: avgSprintKm,
            avgKmPerMatch: totalKm / Double(sessions.count)
        )
    }
}

enum SprintDistanceCalculator {
    /// FIFA-style sprint threshold (km/h).
    static let speedThresholdKmh = 20.0

    static func meters(from samples: [SessionSample]) -> Double {
        let sorted = samples.sorted { $0.tOffsetS < $1.tOffsetS }
        guard sorted.count >= 2 else { return 0 }

        var total: Double = 0
        for index in 0..<(sorted.count - 1) {
            let current = sorted[index]
            let next = sorted[index + 1]
            let deltaS = Double(next.tOffsetS - current.tOffsetS)
            guard deltaS > 0 else { continue }

            let speedKmh = current.speedKmh ?? next.speedKmh ?? 0
            guard speedKmh >= speedThresholdKmh else { continue }
            total += (speedKmh / 3.6) * deltaS
        }
        return total
    }

    static func estimatedMeters(sprints: Int, totalDistanceM: Double) -> Double {
        guard sprints > 0, totalDistanceM > 0 else { return 0 }
        let share = min(0.14, Double(sprints) * 0.009)
        return totalDistanceM * share
    }
}

extension SportSession {
    var sprintDistanceM: Double {
        if let samples, samples.count >= 2 {
            let fromSamples = SprintDistanceCalculator.meters(from: samples)
            if fromSamples > 0 { return fromSamples }
        }
        return SprintDistanceCalculator.estimatedMeters(
            sprints: sprints,
            totalDistanceM: distanceM
        )
    }
}

/// How to label a metric (accumulated vs average vs personal record).
enum PerformanceMetricKind: Equatable {
    case total
    case average
    case record

    var badge: String? {
        switch self {
        case .total: "Total"
        case .average: "Med"
        case .record: "PR"
        }
    }
}
