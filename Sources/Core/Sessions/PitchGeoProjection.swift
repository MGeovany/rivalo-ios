import Foundation

/// Projects GPS coordinates onto an oriented pitch rectangle, yielding
/// normalized pitch coordinates (u along the length 0…1, v across the width
/// 0…1). u = 0 is the own goal, u = 1 the rival goal; attack direction is +u.
///
/// This turns the heatmap from "relative movement spread" into "absolute
/// position on the field" — but only when a geo-reference (center + heading +
/// dimensions) is available. Callers fall back to bounding-box normalization
/// when `reference(from:)` returns nil.
enum PitchGeoProjection {
    struct GeoReference: Equatable {
        let centerLat: Double
        let centerLon: Double
        /// Bearing of the length axis (own goal → rival goal), degrees from north.
        let headingDeg: Double
        let lengthM: Double
        let widthM: Double
    }

    /// Reference from a session's denormalized geo snapshot, if complete.
    static func reference(from session: SportSession) -> GeoReference? {
        guard let lat = session.pitchCenterLat, let lon = session.pitchCenterLon,
              let heading = session.pitchHeadingDeg,
              let length = session.pitchLengthM, length > 0,
              let width = session.pitchWidthM, width > 0
        else { return nil }
        return GeoReference(centerLat: lat, centerLon: lon, headingDeg: heading, lengthM: length, widthM: width)
    }

    /// Reference from a saved pitch, if it carries a heading + dimensions + center.
    static func reference(from pitch: Pitch) -> GeoReference? {
        guard let lat = pitch.latitude, let lon = pitch.longitude,
              let heading = pitch.headingDeg,
              let length = pitch.lengthM, length > 0,
              let width = pitch.widthM, width > 0
        else { return nil }
        return GeoReference(centerLat: lat, centerLon: lon, headingDeg: heading, lengthM: length, widthM: width)
    }

    /// Projects one GPS coordinate to normalized pitch coords (u, v), clamped 0…1.
    static func project(latitude: Double, longitude: Double, ref: GeoReference) -> (u: Double, v: Double) {
        let lat0Rad = ref.centerLat * .pi / 180
        // Equirectangular local meters around the pitch center (good for the
        // ~100 m scale of a pitch).
        let east = (longitude - ref.centerLon) * cos(lat0Rad) * 111_320
        let north = (latitude - ref.centerLat) * 110_540
        // Rotate ENU into the pitch frame. Heading is clockwise from north, so
        // the length axis unit vector is (sinθ east, cosθ north) and the width
        // axis (to its right) is (cosθ east, −sinθ north).
        let theta = ref.headingDeg * .pi / 180
        let along = east * sin(theta) + north * cos(theta)
        let across = east * cos(theta) - north * sin(theta)
        let u = 0.5 + along / ref.lengthM
        let v = 0.5 + across / ref.widthM
        return (min(1, max(0, u)), min(1, max(0, v)))
    }
}
