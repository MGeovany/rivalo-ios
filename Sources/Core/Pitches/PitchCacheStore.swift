import Foundation

/// Local cache of pitches from the API (offline court list on iPhone).
enum PitchCacheStore {
    private static let key = "rivalo.pitches.cache.v1"

    static func load() -> [Pitch] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let pitches = try? JSONDecoder().decode([Pitch].self, from: data)
        else { return [] }
        return pitches
    }

    static func save(_ pitches: [Pitch]) {
        guard let data = try? JSONEncoder().encode(pitches) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
