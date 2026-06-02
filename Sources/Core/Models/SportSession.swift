import Foundation

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
    }
}
