import Foundation

/// Creates a session from a watch payload and applies match context + local venue meta.
enum WatchSessionUpload {
    static func createFromWatch(
        accessToken: String,
        payload: NewSportSession,
        apiClient: APIClient
    ) async throws -> SportSession {
        var created = try await apiClient.createSession(accessToken, enrichGeoReference(payload))

        let context = SessionContextUpdate(
            matchType: payload.matchType,
            surface: payload.surface,
            pitchId: payload.pitchId
        )
        if context.matchType != nil || context.surface != nil || context.pitchId != nil {
            if let patched = try? await apiClient.patchSessionContext(accessToken, created.id, context) {
                created = patched
            }
        }

        var meta = SessionMetaStore.load(sessionId: created.id)
        var changed = false
        if let name = payload.pitchName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            meta.venueName = name
            changed = true
        }
        if let lat = payload.pitchLatitude, let lon = payload.pitchLongitude {
            meta.latitude = lat
            meta.longitude = lon
            changed = true
        }
        if changed {
            SessionMetaStore.save(sessionId: created.id, meta: meta)
        }

        let lastConfig = iOSMatchSetup(
            mode: payload.mode,
            matchType: payload.matchType ?? "11-a-side",
            surface: payload.surface ?? "Artificial turf",
            pitchId: payload.pitchId,
            pitchName: payload.pitchName,
            pitchLatitude: payload.pitchLatitude,
            pitchLongitude: payload.pitchLongitude,
            competition: nil
        )
        LastSetupStore.save(lastConfig)

        return created
    }

    /// Fills the session's geo-reference snapshot from the locally-cached pitch
    /// when the watch didn't send one. Denormalizing here means the heatmap can
    /// project to absolute position even if the pitch is later edited or removed.
    private static func enrichGeoReference(_ payload: NewSportSession) -> NewSportSession {
        guard payload.pitchHeadingDeg == nil,
              let pitchId = payload.pitchId,
              let pitch = PitchCacheStore.load().first(where: { $0.id == pitchId }),
              let heading = pitch.headingDeg,
              let lat = pitch.latitude, let lon = pitch.longitude,
              let length = pitch.lengthM, length > 0,
              let width = pitch.widthM, width > 0
        else { return payload }

        var enriched = payload
        enriched.pitchCenterLat = lat
        enriched.pitchCenterLon = lon
        enriched.pitchHeadingDeg = heading
        enriched.pitchLengthM = length
        enriched.pitchWidthM = width
        return enriched
    }
}
