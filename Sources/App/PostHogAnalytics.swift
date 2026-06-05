import Foundation
import PostHog

enum PostHogAnalytics {

    // MARK: - Court measurement

    static func courtMeasureStarted(source: String) {
        PostHogSDK.shared.startSessionRecording(resumeCurrent: true)
        PostHogSDK.shared.capture("court_measure_started", properties: ["source": source])
        captureLog("Court measure flow opened", level: .info, attributes: ["source": source])
    }

    static func watchPitchWalkProgress(
        phase: String,
        liveMeters: Double,
        lengthM: Double?,
        gpsAccuracyM: Double
    ) {
        PostHogSDK.shared.startSessionRecording(resumeCurrent: true)
        var attributes: [String: Any] = [
            "phase": phase,
            "live_meters": liveMeters,
            "gps_accuracy_m": gpsAccuracyM,
        ]
        if let lengthM { attributes["length_m"] = lengthM }
        captureLog("iPhone received watch pitch walk meters", level: .info, attributes: attributes)
        PostHogSDK.shared.capture("watch_pitch_walk_progress", properties: attributes)
    }

    static func watchPitchSaved(lengthM: Double, widthM: Double, method: String?) {
        let attributes: [String: Any] = [
            "length_m": lengthM,
            "width_m": widthM,
            "measurement_method": method ?? "unknown",
        ]
        captureLog("iPhone received watch pitch save payload", level: .info, attributes: attributes)
        PostHogSDK.shared.capture("watch_pitch_saved", properties: attributes)
    }

    static func watchPitchSaveFailed(reason: String) {
        captureLog("Watch pitch save failed on iPhone", level: .warn, attributes: ["reason": reason])
        PostHogSDK.shared.capture("watch_pitch_save_failed", properties: ["reason": reason])
    }

    // MARK: - Match

    static func matchSavedFromWatch(durationS: Int, distanceM: Double, rating: Double?) {
        var attributes: [String: Any] = [
            "duration_s": durationS,
            "distance_m": distanceM,
        ]
        if let rating { attributes["rating"] = rating }
        PostHogSDK.shared.capture("match_saved_from_watch", properties: attributes)
        captureLog(
            "Watch session saved to backend",
            level: .info,
            attributes: attributes
        )
    }

    static func matchSaveFromWatchFailed(error: String) {
        captureLog("Watch session upload to backend failed", level: .error, attributes: ["error": error])
        PostHogSDK.shared.capture("match_save_from_watch_failed", properties: ["error": error])
    }

    // MARK: - Auth errors

    static func authFailed(flow: String, error: String) {
        captureLog("Auth failed", level: .error, attributes: ["flow": flow, "error": error])
        PostHogSDK.shared.capture("auth_failed", properties: ["flow": flow, "error": error])
    }

    // MARK: - API errors

    static func apiError(context: String, error: String) {
        captureLog("API error", level: .error, attributes: ["context": context, "error": error])
        PostHogSDK.shared.capture("api_error", properties: ["context": context, "error": error])
    }

    // MARK: - Internal

    static func captureLog(
        _ message: String,
        level: PostHogLogSeverity,
        attributes: [String: Any] = [:]
    ) {
        PostHogSDK.shared.captureLog(message, level: level, attributes: attributes)
    }
}
