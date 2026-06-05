import Foundation
import PostHog

enum PostHogAnalytics {
    static func courtMeasureStarted(source: String) {
        PostHogSDK.shared.startSessionRecording(resumeCurrent: true)
        PostHogSDK.shared.capture("court_measure_started", properties: ["source": source])
        captureLog(
            "Court measure flow opened",
            level: .info,
            attributes: ["source": source]
        )
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

        captureLog(
            "iPhone received watch pitch walk meters",
            level: .info,
            attributes: attributes
        )
        PostHogSDK.shared.capture("watch_pitch_walk_progress", properties: attributes)
    }

    static func watchPitchSaved(lengthM: Double, widthM: Double, method: String?) {
        let attributes: [String: Any] = [
            "length_m": lengthM,
            "width_m": widthM,
            "measurement_method": method ?? "unknown",
        ]
        captureLog(
            "iPhone received watch pitch save payload",
            level: .info,
            attributes: attributes
        )
        PostHogSDK.shared.capture("watch_pitch_saved", properties: attributes)
    }

    static func watchPitchSaveFailed(reason: String) {
        captureLog(
            "Watch pitch save failed on iPhone",
            level: .warn,
            attributes: ["reason": reason]
        )
    }

    private static func captureLog(
        _ message: String,
        level: PostHogLogSeverity,
        attributes: [String: Any]
    ) {
        PostHogSDK.shared.captureLog(message, level: level, attributes: attributes)
    }
}
