import Foundation
import Testing
@testable import Rivalo

// MARK: - Test helpers

/// Thread-safe mutable box for building mock stores/clients in tests.
private final class Box<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: T
    init(_ value: T) { _value = value }
    var value: T {
        lock.lock(); defer { lock.unlock() }
        return _value
    }
    func set(_ value: T) {
        lock.lock(); _value = value; lock.unlock()
    }
    func mutate(_ transform: (inout T) -> Void) {
        lock.lock(); transform(&_value); lock.unlock()
    }
}

private func session(refresh: String, access: String = "A", ttl: TimeInterval = 3600) -> Session {
    Session(accessToken: access, refreshToken: refresh, userID: "user-1",
            expiresAt: Date().addingTimeInterval(ttl))
}

/// An AuthClient whose `refresh` is mocked; other endpoints are unused.
private func mockAuthClient(refresh: @escaping @Sendable (String) async throws -> Session) -> AuthClient {
    AuthClient(
        signUp: { _, _ in .needsEmailConfirmation },
        signIn: { _, _ in throw AuthError.invalidResponse },
        recoverPassword: { _ in },
        refresh: refresh,
        signOut: { _ in }
    )
}

private func inMemoryTokenStore(_ box: Box<Session?>) -> TokenStore {
    TokenStore(
        save: { box.set($0) },
        load: { box.value },
        clear: { box.set(nil) }
    )
}

// MARK: - TokenRefreshCoordinator (the auth bug we fixed)

/// Regression test for the session-revocation bug: each refresh must use the
/// LATEST refresh token from the keychain, never a stale value. Supabase rotates
/// the token on every use and revokes the whole session if one is reused.
@Test func coordinatorUsesTheRotatedTokenOnEachRefresh() async throws {
    let store = Box<Session?>(session(refresh: "R1"))
    let received = Box<[String]>([])
    let tokenStore = inMemoryTokenStore(store)
    let auth = mockAuthClient { token in
        received.mutate { $0.append(token) }
        let next = received.value.count + 1
        return session(refresh: "R\(next)")
    }

    let coordinator = TokenRefreshCoordinator()
    _ = try await coordinator.refresh(authClient: auth, tokenStore: tokenStore)
    _ = try await coordinator.refresh(authClient: auth, tokenStore: tokenStore)

    // Second refresh must use R2 (the rotated token), NOT R1 again.
    #expect(received.value == ["R1", "R2"])
}

/// Concurrent 401s must collapse into a single refresh network call, so two
/// parallel refreshes never use the same token twice.
@Test func coordinatorCoalescesConcurrentRefreshes() async throws {
    let store = Box<Session?>(session(refresh: "R1"))
    let refreshCount = Box<Int>(0)
    let tokenStore = inMemoryTokenStore(store)
    let auth = mockAuthClient { _ in
        refreshCount.mutate { $0 += 1 }
        try? await Task.sleep(nanoseconds: 50_000_000) // overlap window
        return session(refresh: "R2")
    }

    let coordinator = TokenRefreshCoordinator()
    await withTaskGroup(of: Void.self) { group in
        for _ in 0..<5 {
            group.addTask {
                _ = try? await coordinator.refresh(authClient: auth, tokenStore: tokenStore)
            }
        }
    }

    #expect(refreshCount.value == 1)
}

/// After the server rejects the token (`.unauthorized`), the circuit breaker
/// fails fast for a cooldown so the app stops hammering the auth endpoint.
@Test func coordinatorTripsBreakerOnUnauthorized() async throws {
    let store = Box<Session?>(session(refresh: "R1"))
    let networkCalls = Box<Int>(0)
    let tokenStore = inMemoryTokenStore(store)
    let auth = mockAuthClient { _ in
        networkCalls.mutate { $0 += 1 }
        throw AuthError.unauthorized("invalid_grant")
    }

    let coordinator = TokenRefreshCoordinator()
    await #expect(throws: AuthError.self) {
        _ = try await coordinator.refresh(authClient: auth, tokenStore: tokenStore)
    }
    // Second call within the cooldown must short-circuit (no extra network call).
    await #expect(throws: AuthError.self) {
        _ = try await coordinator.refresh(authClient: auth, tokenStore: tokenStore)
    }
    #expect(networkCalls.value == 1)
}

// MARK: - GeoMath (pitch measurement by walking)

@Test func distanceMatchesKnownLatitudeSpan() {
    // ~0.001° of latitude ≈ 111 m.
    let d = GeoMath.distanceM(lat1: 0, lon1: 0, lat2: 0.001, lon2: 0)
    #expect(abs(d - 111) < 2)
}

@Test func bearingIsNorthAndEast() {
    let north = GeoMath.bearingDeg(lat1: 0, lon1: 0, lat2: 1, lon2: 0)
    #expect(north < 0.5 || north > 359.5)
    let east = GeoMath.bearingDeg(lat1: 0, lon1: 0, lat2: 0, lon2: 1)
    #expect(abs(east - 90) < 0.5)
}

@Test func midpointIsTheAverage() {
    let mid = GeoMath.midpoint(lat1: 0, lon1: 0, lat2: 10, lon2: 20)
    #expect(abs(mid.lat - 5) < 0.0001)
    #expect(abs(mid.lon - 10) < 0.0001)
}

// MARK: - PitchGeoProjection (absolute-position heatmap)

@Test func projectsCenterToMiddleOfPitch() {
    let ref = PitchGeoProjection.GeoReference(
        centerLat: 10, centerLon: 20, headingDeg: 0, lengthM: 100, widthM: 60
    )
    let (u, v) = PitchGeoProjection.project(latitude: 10, longitude: 20, ref: ref)
    #expect(abs(u - 0.5) < 0.001)
    #expect(abs(v - 0.5) < 0.001)
}

@Test func projectsTowardRivalGoalAlongHeading() {
    // Heading 0 = north points toward the rival goal (+u). A point ~25 m north
    // of center should land at u ≈ 0.75 on a 100 m pitch.
    let ref = PitchGeoProjection.GeoReference(
        centerLat: 0, centerLon: 0, headingDeg: 0, lengthM: 100, widthM: 60
    )
    let north25 = 25.0 / 110_540.0
    let (u, _) = PitchGeoProjection.project(latitude: north25, longitude: 0, ref: ref)
    #expect(u > 0.70 && u < 0.80)
}
