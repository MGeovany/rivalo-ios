import Foundation

/// User profile as returned by the backend `/v1/me` endpoints.
struct Profile: Equatable, Codable, Identifiable {
    let id: String
    var displayName: String
    var preferredPosition: String?
    var heightCm: Int?
    var weightKg: Double?
    var birthYear: Int?
    /// Full date of birth as "YYYY-MM-DD". birthYear is derived from it server-side.
    var birthDate: String?
}

/// Fields sent when updating the profile (PUT /v1/me).
struct ProfileUpdate: Equatable, Encodable {
    var displayName: String
    var preferredPosition: String?
    var heightCm: Int?
    var weightKg: Double?
    var birthYear: Int?
    /// Full date of birth as "YYYY-MM-DD"; the server derives birthYear from it.
    var birthDate: String?
}
