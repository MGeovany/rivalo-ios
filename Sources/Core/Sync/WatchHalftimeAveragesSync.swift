import Foundation
import WatchConnectivity

/// Pushes per-match averages to the watch for halftime comparison.
enum WatchHalftimeAveragesSync {
    static func push(from sessions: [SportSession]) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }

        let payload = averagesPayload(from: sessions)
        guard !payload.isEmpty else { return }

        var context = session.applicationContext
        context["user_averages"] = payload
        try? session.updateApplicationContext(context)
    }

    private static func averagesPayload(from sessions: [SportSession]) -> [String: Any] {
        let played = sessions.filter { $0.durationS > 0 && $0.distanceM > 0 }
        guard !played.isEmpty else { return [:] }

        let count = Double(played.count)
        let avgDistance = played.map(\.distanceM).reduce(0, +) / count / 2
        let avgSprints = Double(played.map(\.sprints).reduce(0, +)) / count / 2
        let speeds = played.compactMap(\.speedMaxKmh)
        var payload: [String: Any] = [
            "avg_distance_m": avgDistance,
            "avg_sprints": avgSprints,
        ]
        if !speeds.isEmpty {
            payload["avg_top_speed_kmh"] = speeds.reduce(0, +) / Double(speeds.count)
        }
        return payload
    }
}
