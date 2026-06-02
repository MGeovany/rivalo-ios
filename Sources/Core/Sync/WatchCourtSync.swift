import Foundation
import WatchConnectivity

/// Pushes known courts from iPhone session metadata to the watch (GPS matching).
enum WatchCourtSync {
    static func pushCourts(for sessions: [SportSession]) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }

        var merged: [String: [String: Any]] = [:]
        let formatter = ISO8601DateFormatter()

        for sportSession in sessions {
            let meta = SessionMetaStore.load(sessionId: sportSession.id)
            guard
                let name = meta.venueName?.trimmingCharacters(in: .whitespacesAndNewlines),
                !name.isEmpty,
                let lat = meta.latitude,
                let lon = meta.longitude
            else { continue }

            let key = sportSession.pitchId ?? name.lowercased()
            var entry: [String: Any] = [
                "id": key,
                "name": name,
                "latitude": lat,
                "longitude": lon,
                "play_count": 1,
            ]
            entry["last_played_at"] = formatter.string(from: sportSession.startedAt)

            if let existing = merged[key] {
                let existingCount = existing["play_count"] as? Int ?? 1
                entry["play_count"] = existingCount + 1
                if let existingDate = existing["last_played_at"] as? String,
                   let newDate = entry["last_played_at"] as? String,
                   existingDate > newDate {
                    entry["last_played_at"] = existingDate
                }
            }
            merged[key] = entry
        }

        guard !merged.isEmpty else { return }

        var context = session.applicationContext
        context["courts"] = Array(merged.values)
        try? session.updateApplicationContext(context)
    }
}
