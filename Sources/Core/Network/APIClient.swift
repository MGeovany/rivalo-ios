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
    /// Patches post-match context via `PATCH /v1/sessions/{id}`.
    var patchSessionContext: @Sendable (_ accessToken: String, _ id: String, _ update: SessionContextUpdate) async throws -> SportSession
    /// Updates a session via `PUT /v1/sessions/{id}`.
    var updateSession: @Sendable (_ accessToken: String, _ id: String, _ update: SportSessionUpdate) async throws -> SportSession
    /// Deletes a session via `DELETE /v1/sessions/{id}`.
    var deleteSession: @Sendable (_ accessToken: String, _ id: String) async throws -> Void
    /// Lists saved pitches via `GET /v1/pitches`.
    var listPitches: @Sendable (_ accessToken: String) async throws -> [Pitch]
    /// Creates a pitch via `POST /v1/pitches`.
    var createPitch: @Sendable (_ accessToken: String, _ new: NewPitch) async throws -> Pitch
    /// Updates a pitch via `PUT /v1/pitches/{id}`.
    var updatePitch: @Sendable (_ accessToken: String, _ id: String, _ update: PitchUpdate) async throws -> Pitch
    /// Deletes a pitch via `DELETE /v1/pitches/{id}`.
    var deletePitch: @Sendable (_ accessToken: String, _ id: String) async throws -> Void
    /// Fetches aggregate stats for a court via `GET /v1/pitches/{id}/stats`.
    var fetchPitchStats: @Sendable (_ accessToken: String, _ id: String) async throws -> PitchStats
    /// Fetches personal bests via `GET /v1/sessions/records`.
    var fetchRecords: @Sendable (_ accessToken: String) async throws -> PersonalRecords
    /// Fetches session insights via `GET /v1/sessions/insights`.
    var fetchInsights: @Sendable (_ accessToken: String) async throws -> SessionInsights
    /// Fetches position insights via `GET /v1/sessions/position-insights`.
    var fetchPositionInsights: @Sendable (_ accessToken: String) async throws -> PositionInsights
    /// Fetches streaks via `GET /v1/sessions/streaks`.
    var fetchStreaks: @Sendable (_ accessToken: String) async throws -> Streaks
    /// Fetches the weekly recap via `GET /v1/recap/weekly`.
    var fetchWeeklyRecap: @Sendable (_ accessToken: String) async throws -> WeeklyRecap
    /// Fetches achievement badges via `GET /v1/badges`.
    var fetchBadges: @Sendable (_ accessToken: String) async throws -> [Badge]
    /// Fetches rivalry histories via `GET /v1/rivalries`.
    var fetchRivalries: @Sendable (_ accessToken: String) async throws -> [Rivalry]
    /// Lists personal goals via `GET /v1/goals`.
    var fetchGoals: @Sendable (_ accessToken: String) async throws -> [Goal]
    /// Creates a personal goal via `POST /v1/goals`.
    var createGoal: @Sendable (_ accessToken: String, _ new: NewGoal) async throws -> Goal
    /// Updates a personal goal via `PATCH /v1/goals/{id}`.
    var updateGoal: @Sendable (_ accessToken: String, _ id: String, _ update: GoalUpdate) async throws -> Goal
    /// Deletes a personal goal via `DELETE /v1/goals/{id}`.
    var deleteGoal: @Sendable (_ accessToken: String, _ id: String) async throws -> Void
    /// Permanently deletes the authenticated user's account via `DELETE /v1/me`.
    var deleteAccount: @Sendable (_ accessToken: String) async throws -> Void
}

extension APIClient: DependencyKey {
    static let liveValue = APIClient(
        health: {
            let url = APIConfig.baseURL.appendingPathComponent("health")
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let http = response as? HTTPURLResponse else {
                    let error = APIError.invalidResponse
                    reportAPIFailure(request, error: error)
                    throw error
                }
                guard (200..<300).contains(http.statusCode) else {
                    let error = APIError.statusCode(http.statusCode)
                    reportAPIFailure(request, error: error, statusCode: http.statusCode)
                    throw error
                }
                do {
                    return try JSONDecoder().decode(HealthStatus.self, from: data)
                } catch {
                    reportAPIFailure(request, error: error)
                    throw error
                }
            } catch let error as APIError {
                throw error
            } catch {
                reportAPIFailure(request, error: error)
                throw error
            }
        },
        me: { token in
            @Dependency(\.authClient) var authClient
            @Dependency(\.tokenStore) var tokenStore
            return try await retryOnUnauthorized(token, authClient: authClient, tokenStore: tokenStore) { newToken in
                try await apiSend(authorizedRequest("v1/me", method: "GET", token: newToken), as: Profile.self)
            }
        },
        updateMe: { token, update in
            @Dependency(\.authClient) var authClient
            @Dependency(\.tokenStore) var tokenStore
            return try await retryOnUnauthorized(token, authClient: authClient, tokenStore: tokenStore) { newToken in
                var request = authorizedRequest("v1/me", method: "PUT", token: newToken)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try apiEncoder().encode(update)
                return try await apiSend(request, as: Profile.self)
            }
        },
        createSession: { token, new in
            @Dependency(\.authClient) var authClient
            @Dependency(\.tokenStore) var tokenStore
            return try await retryOnUnauthorized(token, authClient: authClient, tokenStore: tokenStore) { newToken in
                var request = authorizedRequest("v1/sessions", method: "POST", token: newToken)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try apiEncoder().encode(new)
                return try await apiSend(request, as: SportSession.self)
            }
        },
        listSessions: { token in
            @Dependency(\.authClient) var authClient
            @Dependency(\.tokenStore) var tokenStore
            return try await retryOnUnauthorized(token, authClient: authClient, tokenStore: tokenStore) { newToken in
                try await apiSend(authorizedRequest("v1/sessions", method: "GET", token: newToken), as: [SportSession].self)
            }
        },
        getSession: { token, id in
            @Dependency(\.authClient) var authClient
            @Dependency(\.tokenStore) var tokenStore
            return try await retryOnUnauthorized(token, authClient: authClient, tokenStore: tokenStore) { newToken in
                try await apiSend(authorizedRequest("v1/sessions/\(id)", method: "GET", token: newToken), as: SportSession.self)
            }
        },
        patchSessionContext: { token, id, update in
            @Dependency(\.authClient) var authClient
            @Dependency(\.tokenStore) var tokenStore
            return try await retryOnUnauthorized(token, authClient: authClient, tokenStore: tokenStore) { newToken in
                var request = authorizedRequest("v1/sessions/\(id)", method: "PATCH", token: newToken)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try apiEncoder().encode(update)
                return try await apiSend(request, as: SportSession.self)
            }
        },
        updateSession: { token, id, update in
            @Dependency(\.authClient) var authClient
            @Dependency(\.tokenStore) var tokenStore
            return try await retryOnUnauthorized(token, authClient: authClient, tokenStore: tokenStore) { newToken in
                var request = authorizedRequest("v1/sessions/\(id)", method: "PUT", token: newToken)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try apiEncoder().encode(update)
                return try await apiSend(request, as: SportSession.self)
            }
        },
        deleteSession: { token, id in
            @Dependency(\.authClient) var authClient
            @Dependency(\.tokenStore) var tokenStore
            return try await retryOnUnauthorized(token, authClient: authClient, tokenStore: tokenStore) { newToken in
                try await apiSendEmpty(authorizedRequest("v1/sessions/\(id)", method: "DELETE", token: newToken))
            }
        },
        listPitches: { token in
            @Dependency(\.authClient) var authClient
            @Dependency(\.tokenStore) var tokenStore
            return try await retryOnUnauthorized(token, authClient: authClient, tokenStore: tokenStore) { newToken in
                try await apiSend(authorizedRequest("v1/pitches", method: "GET", token: newToken), as: [Pitch].self)
            }
        },
        createPitch: { token, new in
            @Dependency(\.authClient) var authClient
            @Dependency(\.tokenStore) var tokenStore
            return try await retryOnUnauthorized(token, authClient: authClient, tokenStore: tokenStore) { newToken in
                var request = authorizedRequest("v1/pitches", method: "POST", token: newToken)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try apiEncoder().encode(new)
                return try await apiSend(request, as: Pitch.self)
            }
        },
        updatePitch: { token, id, update in
            @Dependency(\.authClient) var authClient
            @Dependency(\.tokenStore) var tokenStore
            return try await retryOnUnauthorized(token, authClient: authClient, tokenStore: tokenStore) { newToken in
                var request = authorizedRequest("v1/pitches/\(id)", method: "PUT", token: newToken)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try apiEncoder().encode(update)
                return try await apiSend(request, as: Pitch.self)
            }
        },
        deletePitch: { token, id in
            @Dependency(\.authClient) var authClient
            @Dependency(\.tokenStore) var tokenStore
            try await retryOnUnauthorized(token, authClient: authClient, tokenStore: tokenStore) { newToken in
                try await apiSendEmpty(authorizedRequest("v1/pitches/\(id)", method: "DELETE", token: newToken))
            }
        },
        fetchPitchStats: { token, id in
            @Dependency(\.authClient) var authClient
            @Dependency(\.tokenStore) var tokenStore
            return try await retryOnUnauthorized(token, authClient: authClient, tokenStore: tokenStore) { newToken in
                try await apiSend(authorizedRequest("v1/pitches/\(id)/stats", method: "GET", token: newToken), as: PitchStats.self)
            }
        },
        fetchRecords: { token in
            @Dependency(\.authClient) var authClient
            @Dependency(\.tokenStore) var tokenStore
            return try await retryOnUnauthorized(token, authClient: authClient, tokenStore: tokenStore) { newToken in
                try await apiSend(authorizedRequest("v1/sessions/records", method: "GET", token: newToken), as: PersonalRecords.self)
            }
        },
        fetchInsights: { token in
            @Dependency(\.authClient) var authClient
            @Dependency(\.tokenStore) var tokenStore
            return try await retryOnUnauthorized(token, authClient: authClient, tokenStore: tokenStore) { newToken in
                try await apiSend(authorizedRequest("v1/sessions/insights", method: "GET", token: newToken), as: SessionInsights.self)
            }
        },
        fetchPositionInsights: { token in
            @Dependency(\.authClient) var authClient
            @Dependency(\.tokenStore) var tokenStore
            return try await retryOnUnauthorized(token, authClient: authClient, tokenStore: tokenStore) { newToken in
                try await apiSend(authorizedRequest("v1/sessions/position-insights", method: "GET", token: newToken), as: PositionInsights.self)
            }
        },
        fetchStreaks: { token in
            @Dependency(\.authClient) var authClient
            @Dependency(\.tokenStore) var tokenStore
            return try await retryOnUnauthorized(token, authClient: authClient, tokenStore: tokenStore) { newToken in
                try await apiSend(authorizedRequest("v1/sessions/streaks", method: "GET", token: newToken), as: Streaks.self)
            }
        },
        fetchWeeklyRecap: { token in
            @Dependency(\.authClient) var authClient
            @Dependency(\.tokenStore) var tokenStore
            return try await retryOnUnauthorized(token, authClient: authClient, tokenStore: tokenStore) { newToken in
                try await apiSend(authorizedRequest("v1/recap/weekly", method: "GET", token: newToken), as: WeeklyRecap.self)
            }
        },
        fetchBadges: { token in
            @Dependency(\.authClient) var authClient
            @Dependency(\.tokenStore) var tokenStore
            return try await retryOnUnauthorized(token, authClient: authClient, tokenStore: tokenStore) { newToken in
                try await apiSend(authorizedRequest("v1/badges", method: "GET", token: newToken), as: BadgesEnvelope.self).badges
            }
        },
        fetchRivalries: { token in
            @Dependency(\.authClient) var authClient
            @Dependency(\.tokenStore) var tokenStore
            return try await retryOnUnauthorized(token, authClient: authClient, tokenStore: tokenStore) { newToken in
                try await apiSend(authorizedRequest("v1/rivalries", method: "GET", token: newToken), as: [Rivalry].self)
            }
        },
        fetchGoals: { token in
            @Dependency(\.authClient) var authClient
            @Dependency(\.tokenStore) var tokenStore
            return try await retryOnUnauthorized(token, authClient: authClient, tokenStore: tokenStore) { newToken in
                try await apiSend(authorizedRequest("v1/goals", method: "GET", token: newToken), as: [Goal].self)
            }
        },
        createGoal: { token, new in
            @Dependency(\.authClient) var authClient
            @Dependency(\.tokenStore) var tokenStore
            return try await retryOnUnauthorized(token, authClient: authClient, tokenStore: tokenStore) { newToken in
                var request = authorizedRequest("v1/goals", method: "POST", token: newToken)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try apiEncoder().encode(new)
                return try await apiSend(request, as: Goal.self)
            }
        },
        updateGoal: { token, id, update in
            @Dependency(\.authClient) var authClient
            @Dependency(\.tokenStore) var tokenStore
            return try await retryOnUnauthorized(token, authClient: authClient, tokenStore: tokenStore) { newToken in
                var request = authorizedRequest("v1/goals/\(id)", method: "PATCH", token: newToken)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try apiEncoder().encode(update)
                return try await apiSend(request, as: Goal.self)
            }
        },
        deleteGoal: { token, id in
            @Dependency(\.authClient) var authClient
            @Dependency(\.tokenStore) var tokenStore
            try await retryOnUnauthorized(token, authClient: authClient, tokenStore: tokenStore) { newToken in
                try await apiSendEmpty(authorizedRequest("v1/goals/\(id)", method: "DELETE", token: newToken))
            }
        },
        deleteAccount: { token in
            @Dependency(\.authClient) var authClient
            @Dependency(\.tokenStore) var tokenStore
            try await retryOnUnauthorized(token, authClient: authClient, tokenStore: tokenStore) { newToken in
                try await apiSendEmpty(authorizedRequest("v1/me", method: "DELETE", token: newToken))
            }
        }
    )
}

/// Coalesces concurrent token refreshes into a single network call. Supabase
/// rotates the refresh token on every use, so two parallel refreshes with the
/// same token would invalidate the session — this serializes them so concurrent
/// 401s share one refresh and all receive the new session.
private actor TokenRefreshCoordinator {
    static let shared = TokenRefreshCoordinator()
    private var inFlight: Task<Session, Error>?

    func refresh(
        refreshToken: String,
        authClient: AuthClient,
        tokenStore: TokenStore
    ) async throws -> Session {
        if let inFlight {
            return try await inFlight.value
        }
        let task = Task { () throws -> Session in
            let session = try await authClient.refresh(refreshToken)
            try? tokenStore.save(session)
            return session
        }
        inFlight = task
        defer { inFlight = nil }
        return try await task.value
    }
}

/// Wraps an authenticated API call with automatic token refresh on 401. Refresh
/// is coalesced; if another request already refreshed, the freshest keychain
/// token is reused instead of refreshing again.
private func retryOnUnauthorized<T>(
    _ token: String,
    authClient: AuthClient,
    tokenStore: TokenStore,
    operation: @escaping (String) async throws -> T
) async throws -> T {
    do {
        return try await operation(token)
    } catch APIError.statusCode(401) {
        guard let stored = tokenStore.load() else { throw APIError.statusCode(401) }
        // Another in-flight request may have already refreshed the session.
        if stored.accessToken != token {
            return try await operation(stored.accessToken)
        }
        let session = try await TokenRefreshCoordinator.shared.refresh(
            refreshToken: stored.refreshToken,
            authClient: authClient,
            tokenStore: tokenStore
        )
        return try await operation(session.accessToken)
    }
}

private func apiSendEmpty(_ request: URLRequest) async throws {
    do {
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            let error = APIError.invalidResponse
            reportAPIFailure(request, error: error)
            throw error
        }
        guard (200..<300).contains(http.statusCode) else {
            let error = APIError.statusCode(http.statusCode)
            if http.statusCode != 401 {
                reportAPIFailure(request, error: error, statusCode: http.statusCode)
            }
            throw error
        }
    } catch let error as APIError {
        throw error
    } catch {
        reportAPIFailure(request, error: error)
        throw error
    }
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
    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            let error = APIError.invalidResponse
            reportAPIFailure(request, error: error)
            throw error
        }
        guard (200..<300).contains(http.statusCode) else {
            let error = APIError.statusCode(http.statusCode)
            if http.statusCode != 401 {
                reportAPIFailure(request, error: error, statusCode: http.statusCode)
            }
            throw error
        }
        do {
            return try apiDecoder().decode(T.self, from: data)
        } catch {
            reportAPIFailure(request, error: error)
            throw error
        }
    } catch let error as APIError {
        throw error
    } catch {
        reportAPIFailure(request, error: error)
        throw error
    }
}

private func reportAPIFailure(
    _ request: URLRequest,
    error: Error,
    statusCode: Int? = nil
) {
    let path = request.url?.path ?? request.url?.absoluteString ?? "unknown"
    let method = request.httpMethod ?? "GET"
    PostHogAnalytics.apiRequestFailed(
        method: method,
        path: path,
        error: error,
        statusCode: statusCode
    )
}

extension DependencyValues {
    var apiClient: APIClient {
        get { self[APIClient.self] }
        set { self[APIClient.self] = newValue }
    }
}
