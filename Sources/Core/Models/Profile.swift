import Foundation

/// User profile as returned by the backend `/v1/me` endpoints.
struct Profile: Equatable, Codable, Identifiable {
    let id: String
    var displayName: String
    var preferredPosition: String?
    var heightCm: Int?
    var weightKg: Double?
}

/// Fields sent when updating the profile (PUT /v1/me).
struct ProfileUpdate: Equatable, Encodable {
    var displayName: String
    var preferredPosition: String?
    var heightCm: Int?
    var weightKg: Double?
}
