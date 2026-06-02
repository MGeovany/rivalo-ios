import Foundation

/// Creates a session from a watch payload and applies match context + local venue meta.
enum WatchSessionUpload {
    static func createFromWatch(
        accessToken: String,
        payload: NewSportSession,
        apiClient: APIClient
    ) async throws -> SportSession {
        var created = try await apiClient.createSession(accessToken, payload)

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

        return created
    }
}
