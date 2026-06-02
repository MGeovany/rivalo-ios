import Foundation

/// One point in a session's time series (heart rate / speed over time).
struct SessionSample: Equatable, Codable, Sendable, Identifiable {
    let tOffsetS: Int
    let hr: Int?
    let speedKmh: Double?
    /// 1 or 2 for structured matches; nil otherwise.
    var half: Int?

    var id: Int { tOffsetS }
}

/// One GPS point on the pitch trajectory (V2 `session_path`).
struct SessionPathPoint: Equatable, Codable, Sendable, Identifiable {
    let tOffsetS: Int
    let latitude: Double
    let longitude: Double

    var id: Int { tOffsetS }
}

/// Per-half metrics for a structured session (Fatigue Drop).
struct FatigueDrop: Equatable, Codable, Sendable {
    let firstHalf: HalfMetrics
    let secondHalf: HalfMetrics
    let dropPercentage: Double
    let hrAvgPctChange: Double?
    let highIntensityPctChange: Double?
}

struct HalfMetrics: Equatable, Codable, Sendable {
    let distanceM: Double
    let hrAvg: Double?
    let speedMaxKmh: Double?
    let highIntensityS: Int
    let sampleCount: Int
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
    let mode: String?
    let halftimeOffsetS: Int?
    // Post-match context
    let matchType: String?
    let surface: String?
    let position: String?
    let result: String?
    let feeling: Int?
    let matchTag: String?
    let pitchId: String?
    // Structured post-match result
    let opponent: String?
    let outcome: String?
    let score: String?
    let competition: String?
    let goals: Int?
    let assists: Int?
    let notes: String?
    let matchRating: Double?
    let createdAt: Date
    /// Time series; present on detail reads, absent on the list.
    let samples: [SessionSample]?
    /// GPS trajectory; present on detail reads, absent on the list.
    let path: [SessionPathPoint]?
    /// Fatigue Drop (1T vs 2T comparison), computed on-read for structured sessions.
    let fatigueDrop: FatigueDrop?
    /// Personal-best metrics this session broke (present only on the create response).
    let newRecords: [String]?
    /// 1-3 short observations comparing this session to history (present only on the create response).
    let matchInsights: [MatchInsight]?
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

/// Payload sent to PATCH session context (PATCH /v1/sessions/{id}).
struct SessionContextUpdate: Equatable, Encodable, Sendable {
    var matchType: String?
    var surface: String?
    var position: String?
    var result: String?
    var feeling: Int?
    var matchTag: String?
    var pitchId: String?
    // Structured post-match result
    var opponent: String?
    var outcome: String?
    var score: String?
    var competition: String?
    var goals: Int?
    var assists: Int?
    var notes: String?
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
    var mode: String = "quick"
    var matchType: String?
    var surface: String?
    var pitchId: String?
    var pitchName: String?
    var pitchLatitude: Double?
    var pitchLongitude: Double?
    var halftimeOffsetS: Int?
    var samples: [SessionSample]?
    var path: [SessionPathPoint]?
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
        self.mode = (info["mode"] as? String) ?? "quick"
        self.matchType = info["match_type"] as? String
        self.surface = info["surface"] as? String
        self.pitchId = info["pitch_id"] as? String
        self.pitchName = info["pitch_name"] as? String
        self.pitchLatitude = info["pitch_latitude"] as? Double
        self.pitchLongitude = info["pitch_longitude"] as? Double
        self.halftimeOffsetS = info["halftime_offset_s"] as? Int

        if let rawSamples = info["samples"] as? [[String: Any]] {
            self.samples = rawSamples.compactMap { sample in
                guard let offset = sample["t_offset_s"] as? Int else { return nil }
                return SessionSample(
                    tOffsetS: offset,
                    hr: sample["hr"] as? Int,
                    speedKmh: sample["speed_kmh"] as? Double,
                    half: sample["half"] as? Int
                )
            }
        } else {
            self.samples = nil
        }

        if let rawPath = info["path"] as? [[String: Any]] {
            self.path = rawPath.compactMap { point in
                guard
                    let offset = point["t_offset_s"] as? Int,
                    let latitude = point["latitude"] as? Double,
                    let longitude = point["longitude"] as? Double
                else { return nil }
                return SessionPathPoint(tOffsetS: offset, latitude: latitude, longitude: longitude)
            }
        } else {
            self.path = nil
        }
    }
}
