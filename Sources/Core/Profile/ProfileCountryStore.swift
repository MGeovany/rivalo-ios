import Foundation

/// Persists the player's country (ISO 3166-1 alpha-2) for the FUT card until the backend stores it.
enum ProfileCountryStore {
    private static let keyPrefix = "rivalo.profile.country."

    static func load(userId: String) -> String? {
        UserDefaults.standard.string(forKey: keyPrefix + userId)
    }

    static func save(userId: String, code: String) {
        UserDefaults.standard.set(code.uppercased(), forKey: keyPrefix + userId)
    }

    static func delete(userId: String) {
        UserDefaults.standard.removeObject(forKey: keyPrefix + userId)
    }

    /// Device region when the user has not picked a country yet.
    static func defaultCode() -> String {
        if let region = Locale.current.region?.identifier, region.count == 2 {
            return region.uppercased()
        }
        return "US"
    }
}
