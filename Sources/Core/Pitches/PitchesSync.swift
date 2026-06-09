import Foundation

/// Loads pitches from the API, caches them, and syncs to the watch.
enum PitchesSync {
    static func refresh(accessToken: String, apiClient: APIClient) async {
        guard let pitches = try? await apiClient.listPitches(accessToken) else { return }
        PitchCacheStore.save(pitches)
        WatchCourtSync.pushPitches(pitches)
    }

    @discardableResult
    static func create(
        accessToken: String,
        apiClient: APIClient,
        pitch: NewPitch
    ) async throws -> Pitch {
        let created = try await apiClient.createPitch(accessToken, pitch)
        var cached = PitchCacheStore.load()
        if let index = cached.firstIndex(where: { $0.id == created.id }) {
            cached[index] = created
        } else {
            cached.append(created)
        }
        PitchCacheStore.save(cached)
        WatchCourtSync.pushPitches(cached)
        return created
    }

    /// Creates a pitch sent from the watch via WatchConnectivity `userInfo`.
    static func createFromWatchPayload(_ info: [String: Any]) async {
        guard info[WatchCommand.actionKey] as? String == WatchCommand.savePitch else { return }
        guard
            let name = info["name"] as? String,
            !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            let lengthM = info["length_m"] as? Double,
            let widthM = info["width_m"] as? Double,
            lengthM > 0, widthM > 0
        else {
            PostHogAnalytics.watchPitchSaveFailed(reason: "invalid_payload")
            return
        }

        guard let token = TokenStore.liveValue.load()?.accessToken else {
            PostHogAnalytics.watchPitchSaveFailed(reason: "no_access_token")
            return
        }
        let api = APIClient.liveValue

        let method = info["measurement_method"] as? String
        let pitchType = info["type"] as? String
        let surface = info["surface"] as? String
        let lat = info["latitude"] as? Double
        let lon = info["longitude"] as? Double
        let headingDeg = info["heading_deg"] as? Double

        let created = try? await create(
            accessToken: token,
            apiClient: api,
            pitch: NewPitch(
                name: name,
                latitude: lat,
                longitude: lon,
                type: pitchType,
                surface: surface,
                lengthM: lengthM,
                widthM: widthM,
                headingDeg: headingDeg,
                measurementMethod: method
            )
        )
        if created == nil {
            PostHogAnalytics.watchPitchSaveFailed(reason: "api_create_failed")
        }
    }
}
