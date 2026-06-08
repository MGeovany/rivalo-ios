import ComposableArchitecture
import Foundation
import WatchConnectivity

enum WatchCommand {
    static let actionKey = "action"
    static let startMatch = "startMatch"
    static let savePitch = "savePitch"
    // Live match
    static let liveEvent = "liveMatchEvent"
    static let matchPause = "matchPause"
    static let matchResume = "matchResume"
    static let matchHalftime = "matchHalftime"
    static let matchEnd = "matchEnd"
}

enum StartMatchResult: Equatable {
    case started
    case queued
    case unavailable(String)
}

/// Live match event received from the watch.
struct LiveMatchEvent: Equatable, Sendable {
    let mode: String
    /// Absolute time when the match started (used to drive a local clock on iPhone).
    let startedAt: Date
    let heartRate: Int
    let distanceM: Double
    let segment: String
    /// Duration of the first half in seconds. Non-nil once halftime has occurred.
    let halftimeOffsetS: Int?
    /// Absolute time when the halftime break started.
    let halftimeStartedAt: Date?
}

/// Command the user can send from iPhone to the watch.
enum MatchControlCommand: Equatable, Sendable {
    case pause
    case resume
    case halftime
    case end
}

/// Receives finished sessions from the watch and can request a match start on the watch.
@DependencyClient
struct WatchSyncClient {
    /// A stream of sessions received from the watch over WatchConnectivity.
    var incomingSessions: @Sendable () -> AsyncStream<NewSportSession> = { .finished }
    /// Asks the paired watch to begin a HealthKit match capture.
    var startMatch: @Sendable () async -> StartMatchResult = { .unavailable("Watch Connectivity is not available.") }
    /// Stream of live match events from the watch.
    var liveMatchEvents: @Sendable () -> AsyncStream<LiveMatchEvent> = { .finished }
    /// Fires once each time the Watch explicitly ends the match (immediate dismissal signal).
    var matchEndedFromWatch: @Sendable () -> AsyncStream<Void> = { .finished }
    /// Sends a control command to the watch (pause/resume/halftime/end).
    var sendControlCommand: @Sendable (MatchControlCommand) async -> Bool = { _ in false }
}

extension DependencyValues {
    var watchSyncClient: WatchSyncClient {
        get { self[WatchSyncClient.self] }
        set { self[WatchSyncClient.self] = newValue }
    }
}

extension WatchSyncClient: DependencyKey {
    static let liveValue = WatchSyncClient(
        incomingSessions: {
            WatchReceiver.shared.activate()
            return WatchReceiver.shared.stream()
        },
        startMatch: {
            await WatchReceiver.shared.startMatch()
        },
        liveMatchEvents: {
            WatchReceiver.shared.activate()
            return WatchReceiver.shared.liveMatchStream()
        },
        matchEndedFromWatch: {
            WatchReceiver.shared.activate()
            return WatchReceiver.shared.matchEndedStream()
        },
        sendControlCommand: { command in
            await WatchReceiver.shared.sendControlCommand(command)
        }
    )

    static let testValue = WatchSyncClient(
        incomingSessions: { .finished },
        startMatch: { .started },
        liveMatchEvents: { .finished },
        matchEndedFromWatch: { .finished },
        sendControlCommand: { _ in true }
    )
}

/// Bridges WatchConnectivity to AsyncStream and outbound commands.
private final class WatchReceiver: NSObject, WCSessionDelegate, @unchecked Sendable {
    static let shared = WatchReceiver()

    private let lock = NSLock()
    private var continuations: [UUID: AsyncStream<NewSportSession>.Continuation] = [:]
    private var liveContinuations: [UUID: AsyncStream<LiveMatchEvent>.Continuation] = [:]
    private var matchEndedContinuations: [UUID: AsyncStream<Void>.Continuation] = [:]

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        guard session.activationState != .activated else { return }
        // WCSession.activate() must be called from the main thread.
        DispatchQueue.main.async { session.activate() }
    }

    func stream() -> AsyncStream<NewSportSession> {
        AsyncStream { continuation in
            let id = UUID()
            lock.withLock { continuations[id] = continuation }
            continuation.onTermination = { [weak self] _ in
                self?.lock.withLock { _ = self?.continuations.removeValue(forKey: id) }
            }
        }
    }

    func liveMatchStream() -> AsyncStream<LiveMatchEvent> {
        AsyncStream { continuation in
            let id = UUID()
            lock.withLock { liveContinuations[id] = continuation }
            continuation.onTermination = { [weak self] _ in
                self?.lock.withLock { _ = self?.liveContinuations.removeValue(forKey: id) }
            }
        }
    }

    func matchEndedStream() -> AsyncStream<Void> {
        AsyncStream { continuation in
            let id = UUID()
            lock.withLock { matchEndedContinuations[id] = continuation }
            continuation.onTermination = { [weak self] _ in
                self?.lock.withLock { _ = self?.matchEndedContinuations.removeValue(forKey: id) }
            }
        }
    }

    func startMatch() async -> StartMatchResult {
        guard WCSession.isSupported() else {
            return .unavailable("Watch Connectivity is not available on this device.")
        }
        activate()
        let session = WCSession.default

        guard session.isPaired else {
            return .unavailable("Pair an Apple Watch with this device to record a match.")
        }
        guard session.isWatchAppInstalled else {
            return .unavailable("Install Rivalo on your Apple Watch, then try again.")
        }

        let payload = [WatchCommand.actionKey: WatchCommand.startMatch]

        if session.isReachable {
            return await withCheckedContinuation { continuation in
                session.sendMessage(
                    payload,
                    replyHandler: { _ in continuation.resume(returning: .started) },
                    errorHandler: { error in
                        continuation.resume(returning: .unavailable(error.localizedDescription))
                    }
                )
            }
        }

        do {
            try session.updateApplicationContext(payload)
            return .queued
        } catch {
            return .unavailable("Open Rivalo on your Apple Watch and tap Start match.")
        }
    }

    func sendControlCommand(_ command: MatchControlCommand) async -> Bool {
        guard WCSession.isSupported() else { return false }
        let session = WCSession.default
        guard session.activationState == .activated, session.isReachable else { return false }

        let actionKey: String
        switch command {
        case .pause: actionKey = WatchCommand.matchPause
        case .resume: actionKey = WatchCommand.matchResume
        case .halftime: actionKey = WatchCommand.matchHalftime
        case .end: actionKey = WatchCommand.matchEnd
        }

        // Fire-and-forget — the reply/error result is not used by any caller.
        // Avoiding withCheckedContinuation prevents a crash if WCSession calls
        // both reply and error handlers (possible in certain Simulator states).
        session.sendMessage([WatchCommand.actionKey: actionKey], replyHandler: nil, errorHandler: nil)
        return true
    }

    private func emit(_ session: NewSportSession) {
        lock.withLock { continuations.values.forEach { $0.yield(session) } }
    }

    private func emitLiveEvent(_ event: LiveMatchEvent) {
        lock.withLock { liveContinuations.values.forEach { $0.yield(event) } }
    }

    private func emitMatchEnded() {
        lock.withLock { matchEndedContinuations.values.forEach { $0.yield(()) } }
    }

    private func handleWatchCommand(_ payload: [String: Any]) {
        guard let action = payload[WatchCommand.actionKey] as? String else { return }
        if action == WatchCommand.startMatch {
            return
        }
        if action == WatchCommand.matchEnd {
            emitMatchEnded()
            return
        }
        if action == WatchCommand.liveEvent {
            let startedAtMs = payload["started_at_ms"] as? Double ?? 0
            let startedAt = startedAtMs > 0
                ? Date(timeIntervalSince1970: startedAtMs / 1000)
                : Date()
            let halftimeMs = payload["halftime_started_at_ms"] as? Double
            let halftimeStartedAt = halftimeMs.map { Date(timeIntervalSince1970: $0 / 1000) }
            let event = LiveMatchEvent(
                mode: payload["mode"] as? String ?? "quick",
                startedAt: startedAt,
                heartRate: payload["heart_rate"] as? Int ?? 0,
                distanceM: payload["distance_m"] as? Double ?? 0,
                segment: payload["segment"] as? String ?? "firstHalf",
                halftimeOffsetS: payload["halftime_offset_s"] as? Int,
                halftimeStartedAt: halftimeStartedAt
            )
            emitLiveEvent(event)
        }
    }

    // MARK: WCSessionDelegate

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        let action = userInfo[WatchCommand.actionKey] as? String ?? "(workout_summary)"
        let isSummary = userInfo[WatchCommand.actionKey] == nil
        PostHogAnalytics.captureLog(
            "WCSession didReceiveUserInfo",
            level: .info,
            attributes: [
                "action": action,
                "is_workout_summary": isSummary,
                "keys": userInfo.keys.sorted().joined(separator: ","),
            ]
        )

        if userInfo[WatchCommand.actionKey] as? String == WatchCommand.savePitch {
            let lengthM = userInfo["length_m"] as? Double ?? 0
            let widthM = userInfo["width_m"] as? Double ?? 0
            let method = userInfo["measurement_method"] as? String
            PostHogAnalytics.watchPitchSaved(
                lengthM: lengthM,
                widthM: widthM,
                method: method
            )
        }
        if userInfo[WatchCommand.actionKey] as? String == WatchCommand.savePitch,
           let data = try? JSONSerialization.data(withJSONObject: userInfo),
           let copy = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            Task {
                await PitchesSync.createFromWatchPayload(copy)
            }
            return
        }
        if let received = NewSportSession(watchUserInfo: userInfo) {
            PostHogAnalytics.captureLog(
                "watch workout summary parsed — emitting to incomingSessions",
                level: .info,
                attributes: ["duration_s": received.durationS, "distance_m": received.distanceM]
            )
            emit(received)
        } else if isSummary {
            PostHogAnalytics.captureLog(
                "watch userInfo received but NewSportSession init failed — missing required fields",
                level: .error,
                attributes: ["keys": userInfo.keys.sorted().joined(separator: ",")]
            )
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleIncomingMessage(message)
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        handleIncomingMessage(message)
        replyHandler(["status": "ok"])
    }

    /// Routes an inbound message: a workout summary (no action key, parses as a
    /// session) is emitted like a transferUserInfo summary; everything else is a
    /// control command. The watch sends the summary via sendMessage too because
    /// transferUserInfo is unreliable between paired simulators.
    private func handleIncomingMessage(_ message: [String: Any]) {
        if message[WatchCommand.actionKey] == nil,
           let received = NewSportSession(watchUserInfo: message) {
            PostHogAnalytics.captureLog(
                "watch workout summary received via sendMessage — emitting",
                level: .info,
                attributes: ["duration_s": received.durationS, "distance_m": received.distanceM]
            )
            emit(received)
            return
        }
        handleWatchCommand(message)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handleWatchCommand(applicationContext)
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
}
