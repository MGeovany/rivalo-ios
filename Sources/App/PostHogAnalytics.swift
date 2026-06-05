import Foundation
import PostHog

enum PostHogAnalytics {

    // MARK: - Error tracking

    static func captureError(
        _ error: Error,
        context: String,
        extra: [String: Any] = [:]
    ) {
        var properties = extra
        properties["context"] = context
        properties["platform"] = "ios"
        PostHogSDK.shared.captureException(error, properties: properties)
        captureLog(
            "Exception captured",
            level: .error,
            attributes: properties.merging(["message": error.localizedDescription]) { _, new in new }
        )
    }

    static func captureErrorMessage(
        _ message: String,
        context: String,
        extra: [String: Any] = [:]
    ) {
        captureError(
            NSError(
                domain: "com.mgeovany.rivalo",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: message]
            ),
            context: context,
            extra: extra
        )
    }

    // MARK: - Court measurement

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
        captureErrorMessage(reason, context: "watch_pitch_save")
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
        captureErrorMessage(error, context: "watch_session_upload")
    }

    // MARK: - Auth errors

    static func authFailed(flow: String, error: Error) {
        captureError(error, context: "auth", extra: ["flow": flow])
    }

    // MARK: - API errors

    static func apiError(context: String, error: Error) {
        captureError(error, context: context)
    }

    static func apiError(context: String, message: String) {
        captureErrorMessage(message, context: context)
    }

    static func apiRequestFailed(
        method: String,
        path: String,
        error: Error,
        statusCode: Int? = nil
    ) {
        var extra: [String: Any] = [
            "method": method,
            "path": path,
        ]
        if let statusCode { extra["status_code"] = statusCode }
        captureError(error, context: "api_request", extra: extra)
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
