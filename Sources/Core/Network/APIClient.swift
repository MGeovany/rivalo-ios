import ComposableArchitecture
import Foundation

/// Liveness information reported by the backend `/health` endpoint.
struct HealthStatus: Equatable, Decodable {
    let status: String
    let database: String
}

/// Errors surfaced by the API client.
enum APIError: Error, Equatable {
    case invalidResponse
    case statusCode(Int)
}

/// Minimal HTTP client for the backend. Modeled as a dependency so features can
/// be tested with controlled implementations.
@DependencyClient
struct APIClient {
    /// Fetches the backend health status from `GET /health`.
    var health: @Sendable () async throws -> HealthStatus
    /// Fetches the authenticated user's profile from `GET /v1/me`.
    var me: @Sendable (_ accessToken: String) async throws -> Profile
    /// Updates the authenticated user's profile via `PUT /v1/me`.
    var updateMe: @Sendable (_ accessToken: String, _ update: ProfileUpdate) async throws -> Profile
    /// Creates a sport session via `POST /v1/sessions`.
    var createSession: @Sendable (_ accessToken: String, _ new: NewSportSession) async throws -> SportSession
    /// Lists the user's sessions via `GET /v1/sessions`.
    var listSessions: @Sendable (_ accessToken: String) async throws -> [SportSession]
    /// Fetches a single session via `GET /v1/sessions/{id}`.
    var getSession: @Sendable (_ accessToken: String, _ id: String) async throws -> SportSession
}

extension APIClient: DependencyKey {
    static let liveValue = APIClient(
        health: {
            let url = APIConfig.baseURL.appendingPathComponent("health")
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            guard (200..<300).contains(http.statusCode) else {
                throw APIError.statusCode(http.statusCode)
            }
            return try JSONDecoder().decode(HealthStatus.self, from: data)
        },
        me: { token in
            try await apiSend(authorizedRequest("v1/me", method: "GET", token: token), as: Profile.self)
        },
        updateMe: { token, update in
            var request = authorizedRequest("v1/me", method: "PUT", token: token)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try apiEncoder().encode(update)
            return try await apiSend(request, as: Profile.self)
        },
        createSession: { token, new in
            var request = authorizedRequest("v1/sessions", method: "POST", token: token)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try apiEncoder().encode(new)
            return try await apiSend(request, as: SportSession.self)
        },
        listSessions: { token in
            try await apiSend(authorizedRequest("v1/sessions", method: "GET", token: token), as: [SportSession].self)
        },
        getSession: { token, id in
            try await apiSend(authorizedRequest("v1/sessions/\(id)", method: "GET", token: token), as: SportSession.self)
        }
    )
}

// MARK: - Transport helpers

private func apiDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    // Backend timestamps are RFC3339, sometimes with fractional seconds.
    decoder.dateDecodingStrategy = .custom { d in
        let string = try d.singleValueContainer().decode(String.self)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: string) { return date }
        throw DecodingError.dataCorruptedError(
            in: try d.singleValueContainer(),
            debugDescription: "Unrecognized date format: \(string)"
        )
    }
    return decoder
}

private func apiEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.dateEncodingStrategy = .iso8601
    return encoder
}

private func authorizedRequest(_ path: String, method: String, token: String) -> URLRequest {
    var request = URLRequest(url: APIConfig.baseURL.appendingPathComponent(path))
    request.httpMethod = method
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    return request
}

private func apiSend<T: Decodable>(_ request: URLRequest, as _: T.Type) async throws -> T {
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
    guard (200..<300).contains(http.statusCode) else { throw APIError.statusCode(http.statusCode) }
    return try apiDecoder().decode(T.self, from: data)
}

extension DependencyValues {
    var apiClient: APIClient {
        get { self[APIClient.self] }
        set { self[APIClient.self] = newValue }
    }
}
