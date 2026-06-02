import ComposableArchitecture
import Foundation

/// A session received from the watch that is queued for upload to the backend.
struct PendingSession: Codable, Equatable, Sendable, Identifiable {
    let id: UUID
    let payload: NewSportSession
}

/// Durable queue of sessions awaiting upload, so a watch session is never lost
/// when the phone is offline. Backed by a JSON file in Application Support.
@DependencyClient
struct PendingSessionsStore {
    var all: @Sendable () -> [PendingSession] = { [] }
    var enqueue: @Sendable (_ payload: NewSportSession) -> PendingSession = { PendingSession(id: UUID(), payload: $0) }
    var remove: @Sendable (_ id: UUID) -> Void
}

extension DependencyValues {
    var pendingSessions: PendingSessionsStore {
        get { self[PendingSessionsStore.self] }
        set { self[PendingSessionsStore.self] = newValue }
    }
}

// Serializes file access; DispatchQueue is Sendable so it is safe as a global.
private let pendingQueue = DispatchQueue(label: "com.mgeovany.rivalo.pending-sessions")

private func pendingFileURL() -> URL {
    let manager = FileManager.default
    let directory = (try? manager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
        ?? manager.temporaryDirectory
    return directory.appendingPathComponent("pending_sessions.json")
}

private func loadPending() -> [PendingSession] {
    guard let data = try? Data(contentsOf: pendingFileURL()) else { return [] }
    return (try? JSONDecoder().decode([PendingSession].self, from: data)) ?? []
}

private func savePending(_ items: [PendingSession]) {
    guard let data = try? JSONEncoder().encode(items) else { return }
    try? data.write(to: pendingFileURL(), options: .atomic)
}

extension PendingSessionsStore: DependencyKey {
    static let liveValue = PendingSessionsStore(
        all: {
            pendingQueue.sync { loadPending() }
        },
        enqueue: { payload in
            pendingQueue.sync {
                var items = loadPending()
                let pending = PendingSession(id: UUID(), payload: payload)
                items.append(pending)
                savePending(items)
                return pending
            }
        },
        remove: { id in
            pendingQueue.sync {
                var items = loadPending()
                items.removeAll { $0.id == id }
                savePending(items)
            }
        }
    )
}
