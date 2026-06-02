import ComposableArchitecture
import Foundation

/// Outcome of a sign-up attempt.
enum SignUpResult: Equatable {
    /// The account is active and a session was issued.
    case session(Session)
    /// The project requires email confirmation before the account can sign in.
    case needsEmailConfirmation
}

/// Errors surfaced by the auth client. `message` carries a human-readable reason.
enum AuthError: Error, Equatable {
    case message(String)
    case invalidResponse
}

/// Talks to Supabase Auth (GoTrue) over REST for email/password authentication.
/// Modeled as a dependency so features can be tested with controlled values.
@DependencyClient
struct AuthClient {
    var signUp: @Sendable (_ email: String, _ password: String) async throws -> SignUpResult
    var signIn: @Sendable (_ email: String, _ password: String) async throws -> Session
    var refresh: @Sendable (_ refreshToken: String) async throws -> Session
    var signOut: @Sendable (_ accessToken: String) async throws -> Void
}

extension DependencyValues {
    var authClient: AuthClient {
        get { self[AuthClient.self] }
        set { self[AuthClient.self] = newValue }
    }
}

extension AuthClient: DependencyKey {
    static let liveValue: AuthClient = {
        let urlSession = URLSession.shared

        return AuthClient(
            signUp: { email, password in
                let body = try await goTruePost(
                    urlSession,
                    path: "signup",
                    payload: ["email": email, "password": password]
                )
                let decoded = try decoder().decode(signUpResponse.self, from: body)
                if let session = decoded.asSession() {
                    return .session(session)
                }
                return .needsEmailConfirmation
            },
            signIn: { email, password in
                let body = try await goTruePost(
                    urlSession,
                    path: "token",
                    query: "grant_type=password",
                    payload: ["email": email, "password": password]
                )
                return try decoder().decode(tokenResponse.self, from: body).asSession()
            },
            refresh: { refreshToken in
                let body = try await goTruePost(
                    urlSession,
                    path: "token",
                    query: "grant_type=refresh_token",
                    payload: ["refresh_token": refreshToken]
                )
                return try decoder().decode(tokenResponse.self, from: body).asSession()
            },
            signOut: { accessToken in
                _ = try await goTruePost(
                    urlSession,
                    path: "logout",
                    payload: [:],
                    bearer: accessToken
                )
            }
        )
    }()
}

// MARK: - GoTrue transport

private func decoder() -> JSONDecoder {
    let d = JSONDecoder()
    d.keyDecodingStrategy = .convertFromSnakeCase
    return d
}

/// Performs a POST against the GoTrue REST API, returning the response body or
/// throwing an `AuthError.message` parsed from the error body on non-2xx.
private func goTruePost(
    _ urlSession: URLSession,
    path: String,
    query: String? = nil,
    payload: [String: String],
    bearer: String? = nil
) async throws -> Data {
    var components = URLComponents(
        url: SupabaseConfig.url.appendingPathComponent("auth/v1/\(path)"),
        resolvingAgainstBaseURL: false
    )
    components?.query = query
    guard let url = components?.url else { throw AuthError.invalidResponse }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
    if let bearer {
        request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
    } else {
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
    }
    request.httpBody = try JSONSerialization.data(withJSONObject: payload)

    let (data, response) = try await urlSession.data(for: request)
    guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }
    guard (200..<300).contains(http.statusCode) else {
        let parsed = try? decoder().decode(goTrueError.self, from: data)
        throw AuthError.message(parsed?.text ?? "Authentication failed (\(http.statusCode))")
    }
    return data
}

// MARK: - Wire formats

private struct goTrueUser: Decodable { let id: String }

private struct tokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let user: goTrueUser

    func asSession() -> Session {
        Session(
            accessToken: accessToken,
            refreshToken: refreshToken,
            userID: user.id,
            expiresAt: Date().addingTimeInterval(TimeInterval(expiresIn))
        )
    }
}

private struct signUpResponse: Decodable {
    let accessToken: String?
    let refreshToken: String?
    let expiresIn: Int?
    let user: goTrueUser?

    func asSession() -> Session? {
        guard let accessToken, let refreshToken, let expiresIn, let user else { return nil }
        return Session(
            accessToken: accessToken,
            refreshToken: refreshToken,
            userID: user.id,
            expiresAt: Date().addingTimeInterval(TimeInterval(expiresIn))
        )
    }
}

private struct goTrueError: Decodable {
    let msg: String?
    let error: String?
    let errorDescription: String?
    let message: String?

    var text: String {
        msg ?? errorDescription ?? error ?? message ?? "Authentication failed"
    }
}
