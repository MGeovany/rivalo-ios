import ComposableArchitecture
import Foundation
import WatchConnectivity

/// Receives finished sessions transferred from the Apple Watch.
@DependencyClient
struct WatchSyncClient {
    /// A stream of sessions received from the watch over WatchConnectivity.
    /// Activating the session happens on first use.
    var incomingSessions: @Sendable () -> AsyncStream<NewSportSession> = { .finished }
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
        }
    )
}

/// Bridges the delegate-based WatchConnectivity API to an AsyncStream. Marked
/// `@unchecked Sendable` because access to its mutable state is guarded by a lock.
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
