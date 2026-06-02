import Foundation
import WatchConnectivity

/// Pushes saved pitches to the watch for GPS-based court selection.
enum WatchCourtSync {
    /// Syncs API pitches (with dimensions + location) to the watch.
    static func pushPitches(_ pitches: [Pitch]) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }

        let courts = pitches.map { courtPayload(from: $0, playCount: 0) }
        guard !courts.isEmpty else { return }

        var context = session.applicationContext
        context["courts"] = courts
        try? session.updateApplicationContext(context)
    }

    /// Merges session venue history with API pitches for the watch list.
    static func pushCourts(for sessions: [SportSession]) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }

        var merged: [String: [String: Any]] = [:]
        let formatter = ISO8601DateFormatter()

        for pitch in PitchCacheStore.load() {
            merged[pitch.id] = courtPayload(from: pitch, playCount: 0)
        }

        for sportSession in sessions {
            let meta = SessionMetaStore.load(sessionId: sportSession.id)
            guard
                let name = meta.venueName?.trimmingCharacters(in: .whitespacesAndNewlines),
                !name.isEmpty,
                let lat = meta.latitude,
                let lon = meta.longitude
            else { continue }

            let key = sportSession.pitchId ?? name.lowercased()
            var entry = merged[key] ?? [
                "id": key,
                "name": name,
                "latitude": lat,
                "longitude": lon,
                "play_count": 0,
            ]
            entry["play_count"] = (entry["play_count"] as? Int ?? 0) + 1
            entry["last_played_at"] = formatter.string(from: sportSession.startedAt)
            if let pitchId = sportSession.pitchId, let pitch = PitchCacheStore.load().first(where: { $0.id == pitchId }) {
                entry["length_m"] = pitch.lengthM
                entry["width_m"] = pitch.widthM
                entry["measurement_method"] = pitch.measurementMethod
            }
            merged[key] = entry
        }

        guard !merged.isEmpty else { return }

        var context = session.applicationContext
        context["courts"] = Array(merged.values)
        try? session.updateApplicationContext(context)
    }

    private static func courtPayload(from pitch: Pitch, playCount: Int) -> [String: Any] {
        var entry: [String: Any] = [
            "id": pitch.id,
            "name": pitch.name,
            "latitude": pitch.latitude ?? 0,
            "longitude": pitch.longitude ?? 0,
            "play_count": playCount,
        ]
        if let lengthM = pitch.lengthM { entry["length_m"] = lengthM }
        if let widthM = pitch.widthM { entry["width_m"] = widthM }
        if let method = pitch.measurementMethod { entry["measurement_method"] = method }
        return entry
    }
}
