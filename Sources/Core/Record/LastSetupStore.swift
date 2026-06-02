import Foundation

/// Mirrors watch `MatchSetup` fields plus iOS-only `competition`.
struct iOSMatchSetup: Equatable, Codable {
    var mode: String
    var matchType: String
    var surface: String
    var pitchId: String?
    var pitchName: String?
    var pitchLatitude: Double?
    var pitchLongitude: Double?
    var competition: String?
}

extension iOSMatchSetup {
    static let `default` = iOSMatchSetup(
        mode: "quick",
        matchType: "11-a-side",
        surface: "Artificial turf",
        pitchId: nil,
        pitchName: nil,
        pitchLatitude: nil,
        pitchLongitude: nil,
        competition: nil
    )
}

// MARK: - Persistence

enum LastSetupStore {
    private static let key = "lastMatchSetup"

    static func save(_ setup: iOSMatchSetup) {
        guard let data = try? JSONEncoder().encode(setup) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func load() -> iOSMatchSetup? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let setup = try? JSONDecoder().decode(iOSMatchSetup.self, from: data)
        else { return nil }
        return setup
    }
}
