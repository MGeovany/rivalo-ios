import Foundation

/// Saved pitch/court from `GET/POST /v1/pitches`.
struct Pitch: Equatable, Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let latitude: Double?
    let longitude: Double?
    let type: String?
    let surface: String?
    let lengthM: Double?
    let widthM: Double?
    /// Bearing of the long axis (own goal -> rival goal) in degrees from north.
    let headingDeg: Double?
    let measurementMethod: String?
    let indoor: Bool?
    let notes: String?

    var hasDimensions: Bool {
        guard let lengthM, let widthM else { return false }
        return lengthM > 0 && widthM > 0
    }

    var dimensionsText: String? {
        guard hasDimensions, let lengthM, let widthM else { return nil }
        return String(format: "%.0f × %.0f m", lengthM, widthM)
    }
}

/// Body for `POST /v1/pitches`.
struct NewPitch: Equatable, Encodable, Sendable {
    var name: String
    var latitude: Double?
    var longitude: Double?
    var type: String?
    var surface: String?
    var lengthM: Double?
    var widthM: Double?
    var headingDeg: Double?
    var measurementMethod: String?
    var indoor: Bool?
    var notes: String?
}

/// Aggregate session stats for one court (`GET /v1/pitches/{id}/stats`).
struct PitchStats: Equatable, Codable, Sendable {
    var matchCount: Int
    var avgRating: Double?
    var avgDistanceM: Double?
    var avgSprints: Double?
    var lastPlayedAt: Date?
    var records: [RecordEntry] = []
}

/// Body for `PUT /v1/pitches/{id}` (all optional; nil leaves the field unchanged).
struct PitchUpdate: Equatable, Encodable, Sendable {
    var name: String?
    var latitude: Double?
    var longitude: Double?
    var type: String?
    var surface: String?
    var lengthM: Double?
    var widthM: Double?
    var headingDeg: Double?
    var measurementMethod: String?
    var indoor: Bool?
    var notes: String?
}
