import Foundation

/// Local metadata for a session until the backend stores venue and photos.
struct SessionMeta: Equatable, Codable {
    var venueName: String?
    var latitude: Double?
    var longitude: Double?
    /// Whether the teams switched ends at halftime (mirrors 2nd-half positions on
    /// the geo-referenced heatmap). nil = default true (official football).
    var secondHalfSwitchedSides: Bool?

    var flipsSecondHalf: Bool { secondHalfSwitchedSides ?? true }
}

enum SessionMetaStore {
    private static let keyPrefix = "rivalo.session.meta."

    static func load(sessionId: String) -> SessionMeta {
        guard let data = UserDefaults.standard.data(forKey: keyPrefix + sessionId),
              let meta = try? JSONDecoder().decode(SessionMeta.self, from: data)
        else { return SessionMeta() }
        return meta
    }

    static func save(sessionId: String, meta: SessionMeta) {
        guard let data = try? JSONEncoder().encode(meta) else { return }
        UserDefaults.standard.set(data, forKey: keyPrefix + sessionId)
    }

    static func delete(sessionId: String) {
        UserDefaults.standard.removeObject(forKey: keyPrefix + sessionId)
    }
}
