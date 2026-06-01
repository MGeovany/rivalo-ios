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
}

extension APIClient: DependencyKey {
    static let liveValue: APIClient = {
        let session = URLSession.shared
        return APIClient(
            health: {
                let url = APIConfig.baseURL.appendingPathComponent("health")
                let (data, response) = try await session.data(from: url)
                guard let http = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                guard (200..<300).contains(http.statusCode) else {
                    throw APIError.statusCode(http.statusCode)
                }
                return try JSONDecoder().decode(HealthStatus.self, from: data)
            }
        )
    }()
}

extension DependencyValues {
    var apiClient: APIClient {
        get { self[APIClient.self] }
        set { self[APIClient.self] = newValue }
    }
}
