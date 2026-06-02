import ComposableArchitecture
import Foundation
import WatchConnectivity

enum WatchCommand {
    static let actionKey = "action"
    static let methodKey = "method"
    static let startMatch = "startMatch"
    static let measureCourt = "measureCourt"
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
    let elapsedS: Int
    let heartRate: Int
    let distanceM: Double
    let segment: String
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
    /// Opens pitch measurement when the watch requests manual entry on iPhone.
    var incomingMeasureCourt: @Sendable () -> AsyncStream<PitchMeasurementMethod> = { .finished }
    /// Stream of live match events from the watch.
    var liveMatchEvents: @Sendable () -> AsyncStream<LiveMatchEvent> = { .finished }
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
        incomingMeasureCourt: {
            WatchReceiver.shared.activate()
            return WatchReceiver.shared.measureCourtStream()
        },
        liveMatchEvents: {
            WatchReceiver.shared.activate()
            return WatchReceiver.shared.liveMatchStream()
        },
        sendControlCommand: { command in
            await WatchReceiver.shared.sendControlCommand(command)
        }
    )

    static let testValue = WatchSyncClient(
        incomingSessions: { .finished },
        startMatch: { .started },
        incomingMeasureCourt: { .finished },
        liveMatchEvents: { .finished },
        sendControlCommand: { _ in true }
    )
}

/// Bridges WatchConnectivity to AsyncStream and outbound commands.
private final class WatchReceiver: NSObject, WCSessionDelegate, @unchecked Sendable {
    static let shared = WatchReceiver()

    private let lock = NSLock()
    private var continuations: [UUID: AsyncStream<NewSportSession>.Continuation] = [:]
    private var measureContinuations: [UUID: AsyncStream<PitchMeasurementMethod>.Continuation] = [:]
    private var liveContinuations: [UUID: AsyncStream<LiveMatchEvent>.Continuation] = [:]

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        if session.activationState != .activated {
            session.activate()
        }
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

    func measureCourtStream() -> AsyncStream<PitchMeasurementMethod> {
        AsyncStream { continuation in
            let id = UUID()
            lock.withLock { measureContinuations[id] = continuation }
            continuation.onTermination = { [weak self] _ in
                self?.lock.withLock { _ = self?.measureContinuations.removeValue(forKey: id) }
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
        activate()
        let session = WCSession.default
        guard session.isReachable else { return false }

        let actionKey: String
        switch command {
        case .pause: actionKey = WatchCommand.matchPause
        case .resume: actionKey = WatchCommand.matchResume
        case .halftime: actionKey = WatchCommand.matchHalftime
        case .end: actionKey = WatchCommand.matchEnd
        }

        return await withCheckedContinuation { continuation in
            session.sendMessage(
                [WatchCommand.actionKey: actionKey],
                replyHandler: { _ in continuation.resume(returning: true) },
                errorHandler: { _ in continuation.resume(returning: false) }
            )
        }
    }

    private func emit(_ session: NewSportSession) {
        lock.withLock { continuations.values.forEach { $0.yield(session) } }
    }

    private func emitMeasureCourt(_ method: PitchMeasurementMethod) {
        lock.withLock { measureContinuations.values.forEach { $0.yield(method) } }
    }

    private func emitLiveEvent(_ event: LiveMatchEvent) {
        lock.withLock { liveContinuations.values.forEach { $0.yield(event) } }
    }

    private func handleWatchCommand(_ payload: [String: Any]) {
        guard let action = payload[WatchCommand.actionKey] as? String else { return }
        if action == WatchCommand.startMatch {
            return
        }
        if action == WatchCommand.measureCourt,
           let raw = payload[WatchCommand.methodKey] as? String,
           let method = PitchMeasurementMethod(watchRawValue: raw),
           method != .walk {
            emitMeasureCourt(method)
        }
        if action == WatchCommand.liveEvent {
            let event = LiveMatchEvent(
                mode: payload["mode"] as? String ?? "quick",
                elapsedS: payload["elapsed_s"] as? Int ?? 0,
                heartRate: payload["heart_rate"] as? Int ?? 0,
                distanceM: payload["distance_m"] as? Double ?? 0,
                segment: payload["segment"] as? String ?? "firstHalf"
            )
            emitLiveEvent(event)
        }
    }

    // MARK: WCSessionDelegate

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        if userInfo[WatchCommand.actionKey] as? String == WatchCommand.savePitch,
           let data = try? JSONSerialization.data(withJSONObject: userInfo),
           let copy = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            Task {
                await PitchesSync.createFromWatchPayload(copy)
            }
            return
        }
        if let received = NewSportSession(watchUserInfo: userInfo) {
            emit(received)
        }
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        handleWatchCommand(message)
        replyHandler(["status": "ok"])
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handleWatchCommand(applicationContext)
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
}
