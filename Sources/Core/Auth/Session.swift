import Foundation

/// An authenticated session obtained from Supabase Auth.
struct Session: Equatable, Codable {
    var accessToken: String
    var refreshToken: String
    var userID: String
    var expiresAt: Date

    /// Whether the access token is expired (with a small safety margin).
    var isExpired: Bool {
        expiresAt.timeIntervalSinceNow < 30
    }
}
