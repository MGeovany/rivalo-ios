import Foundation

/// One point in a session's time series (heart rate / speed over time).
struct SessionSample: Equatable, Codable, Sendable, Identifiable {
    let tOffsetS: Int
    let hr: Int?
    let speedKmh: Double?

    var id: Int { tOffsetS }
}

/// A recorded sport session as returned by the backend `/v1/sessions` endpoints.
struct SportSession: Equatable, Codable, Identifiable {
    let id: String
    let userId: String
    let startedAt: Date
    let endedAt: Date
    let durationS: Int
    let distanceM: Double
    let hrAvg: Int?
    let hrMax: Int?
    let speedMaxKmh: Double?
    let sprints: Int
    let intensity: Double?
    let caloriesKcal: Double?
    let source: String
    let createdAt: Date
    /// Time series; present on detail reads, absent on the list.
    let samples: [SessionSample]?
}

extension SportSession {
    /// Distance formatted in kilometers, e.g. "8.20 km".
    var distanceKmText: String {
        String(format: "%.2f km", distanceM / 1000)
    }

    /// Duration formatted compactly, e.g. "90 min" or "5m 30s".
    var durationText: String {
        let minutes = durationS / 60
        let seconds = durationS % 60
        return seconds == 0 ? "\(minutes) min" : "\(minutes)m \(seconds)s"
    }

    func asUpdate() -> SportSessionUpdate {
        SportSessionUpdate(
            startedAt: startedAt,
            endedAt: endedAt,
            durationS: durationS,
            distanceM: distanceM,
            hrAvg: hrAvg,
            hrMax: hrMax,
            speedMaxKmh: speedMaxKmh,
            sprints: sprints,
            intensity: intensity,
            caloriesKcal: caloriesKcal
        )
    }
}

/// Payload sent to update a session (PUT /v1/sessions/{id}).
struct SportSessionUpdate: Equatable, Encodable, Sendable {
    var startedAt: Date
    var endedAt: Date
    var durationS: Int
    var distanceM: Double
    var hrAvg: Int?
    var hrMax: Int?
    var speedMaxKmh: Double?
    var sprints: Int
    var intensity: Double?
    var caloriesKcal: Double?
}

/// Payload sent to create a session (POST /v1/sessions).
struct NewSportSession: Equatable, Codable, Sendable {
    var startedAt: Date
    var endedAt: Date
    var durationS: Int
    var distanceM: Double
    var hrAvg: Int?
    var hrMax: Int?
    var sprints: Int
    var intensity: Double?
    var source: String
    var samples: [SessionSample]?
}

extension NewSportSession {
    /// Builds a payload from a WatchConnectivity `userInfo` dictionary sent by the
    /// watch. Returns nil if required fields are missing or malformed.
    init?(watchUserInfo info: [String: Any]) {
        let formatter = ISO8601DateFormatter()
        guard
            let startedRaw = info["started_at"] as? String,
            let endedRaw = info["ended_at"] as? String,
            let started = formatter.date(from: startedRaw),
            let ended = formatter.date(from: endedRaw),
            let duration = info["duration_s"] as? Int
        else { return nil }

        self.startedAt = started
        self.endedAt = ended
        self.durationS = duration
        self.distanceM = (info["distance_m"] as? Double) ?? 0
        self.hrAvg = info["hr_avg"] as? Int
        self.hrMax = info["hr_max"] as? Int
        self.sprints = (info["sprints"] as? Int) ?? 0
        self.intensity = info["intensity"] as? Double
        self.source = (info["source"] as? String) ?? "watch"

        if let rawSamples = info["samples"] as? [[String: Any]] {
            self.samples = rawSamples.compactMap { sample in
                guard let offset = sample["t_offset_s"] as? Int else { return nil }
                return SessionSample(
                    tOffsetS: offset,
                    hr: sample["hr"] as? Int,
                    speedKmh: sample["speed_kmh"] as? Double
                )
            }
        } else {
            self.samples = nil
        }
    }
}
