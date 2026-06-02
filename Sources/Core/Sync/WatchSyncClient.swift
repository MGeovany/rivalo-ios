import ComposableArchitecture
import Foundation
import WatchConnectivity

enum WatchCommand {
    static let actionKey = "action"
    static let startMatch = "startMatch"
}

enum StartMatchResult: Equatable {
    case started
    case queued
    case unavailable(String)
}

/// Receives finished sessions from the watch and can request a match start on the watch.
@DependencyClient
struct WatchSyncClient {
    /// A stream of sessions received from the watch over WatchConnectivity.
    var incomingSessions: @Sendable () -> AsyncStream<NewSportSession> = { .finished }
    /// Asks the paired watch to begin a HealthKit match capture.
    var startMatch: @Sendable () async -> StartMatchResult = { .unavailable("Watch Connectivity is not available.") }
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
        }
    )

    static let testValue = WatchSyncClient(
        incomingSessions: { .finished },
        startMatch: { .started }
    )
}

/// Bridges WatchConnectivity to AsyncStream and outbound commands.
private final class WatchReceiver: NSObject, WCSessionDelegate, @unchecked Sendable {
    static let shared = WatchReceiver()

    private let lock = NSLock()
    private var continuations: [UUID: AsyncStream<NewSportSession>.Continuation] = [:]

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

    func startMatch() async -> StartMatchResult {
        guard WCSession.isSupported() else {
            return .unavailable("Watch Connectivity is not available on this device.")
        }
        activate()
        let session = WCSession.default

        guard session.isPaired else {
            return .unavailable("Pair an Apple Watch with this iPhone to record a match.")
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

    private func emit(_ session: NewSportSession) {
        lock.withLock { continuations.values.forEach { $0.yield(session) } }
    }

    // MARK: WCSessionDelegate

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        if let received = NewSportSession(watchUserInfo: userInfo) {
            emit(received)
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
}
