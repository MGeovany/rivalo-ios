import ComposableArchitecture
import PostHog

/// Root reducer. Restores a stored session on launch and routes between the
/// authentication flow and the signed-in tab bar.
@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var isLoading = true
        var auth = AuthenticationFeature.State()
        var main: MainTabFeature.State?
        var refreshToken: String?
    }

    enum Action {
        case onAppear
        case sessionLoaded(Session?)
        case refreshTimerTick
        case tokenRefreshed(Result<Session, AuthError>)
        case auth(AuthenticationFeature.Action)
        case main(MainTabFeature.Action)
    }

    @Dependency(\.tokenStore) var tokenStore
    @Dependency(\.authClient) var authClient

    var body: some ReducerOf<Self> {
        Scope(state: \.auth, action: \.auth) {
            AuthenticationFeature()
        }

        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    guard let stored = tokenStore.load() else {
                        await send(.sessionLoaded(nil))
                        return
                    }
                    await send(.sessionLoaded(stored))
                }

            case let .sessionLoaded(session):
                state.isLoading = false
                if let session {
                    state.refreshToken = session.refreshToken
                    state.main = MainTabFeature.State(accessToken: session.accessToken)
                    let userId = session.userID
                    return .merge(
                        .run { _ in PostHogSDK.shared.identify(userId) },
                        // If the stored token is already expired, refresh now
                        // instead of waiting for the timer (or a 401 round-trip).
                        session.isExpired ? .send(.refreshTimerTick) : startRefreshTimer(session)
                    )
                }
                return .none

            case .refreshTimerTick:
                return .run { send in
                    guard tokenStore.load()?.refreshToken != nil else { return }
                    // Route through the same coordinator as on-401 refreshes. The
                    // coordinator reads the freshest token from the keychain itself,
                    // so the rotating refresh token is never used twice (Supabase
                    // revokes the whole session on refresh-token reuse).
                    let result = await Result {
                        try await TokenRefreshCoordinator.shared.refresh(
                            authClient: authClient,
                            tokenStore: tokenStore
                        )
                    }.mapError { $0 as? AuthError ?? .invalidResponse }
                    await send(.tokenRefreshed(result))
                }

            case let .tokenRefreshed(.success(session)):
                state.refreshToken = session.refreshToken
                state.main?.accessToken = session.accessToken
                state.main?.sessions.accessToken = session.accessToken
                state.main?.profile.accessToken = session.accessToken
                state.main?.insights.accessToken = session.accessToken
                try? tokenStore.save(session)
                return startRefreshTimer(session)

            case let .tokenRefreshed(.failure(error)):
                switch error {
                case .message, .invalidResponse:
                    // Transient (network blip / 5xx / rate limit). Keep the user
                    // signed in and retry later — a mobile app must not bounce the
                    // user to login over a temporary failure. The session is still
                    // valid; the next refresh (or on-401 retry) will renew it.
                    return .run { send in
                        try await Task.sleep(nanoseconds: 60 * 1_000_000_000)
                        await send(.refreshTimerTick)
                    }
                case .unauthorized:
                    // The refresh token itself was rejected (400/401/403) — the
                    // session is genuinely dead and cannot be renewed, so this is
                    // the one case where re-login is unavoidable.
                    state.main = nil
                    state.refreshToken = nil
                    return .run { _ in
                        PostHogSDK.shared.capture("session_expired_signed_out")
                        PostHogSDK.shared.reset()
                        tokenStore.clear()
                    }
                }

            case let .auth(.delegate(.authenticated(session))):
                state.auth = AuthenticationFeature.State()
                state.refreshToken = session.refreshToken
                state.main = MainTabFeature.State(accessToken: session.accessToken)
                try? tokenStore.save(session)
                let userId = session.userID
                return .merge(
                    .run { _ in PostHogSDK.shared.identify(userId) },
                    startRefreshTimer(session)
                )

            case .main(.delegate(.signOut)):
                let accessToken = state.main?.profile.accessToken
                state.main = nil
                state.refreshToken = nil
                return .run { _ in
                    PostHogSDK.shared.capture("user_signed_out")
                    PostHogSDK.shared.reset()
                    tokenStore.clear()
                    if let accessToken {
                        try? await authClient.signOut(accessToken)
                    }
                }

            case .main(.delegate(.accountDeleted)):
                state.main = nil
                state.refreshToken = nil
                return .run { _ in
                    PostHogSDK.shared.reset()
                    tokenStore.clear()
                }

            case .auth, .main:
                return .none
            }
        }
        .ifLet(\.main, action: \.main) {
            MainTabFeature()
        }
    }

    private func startRefreshTimer(_ session: Session) -> Effect<Action> {
        let timeToRefresh = max(session.expiresAt.timeIntervalSinceNow - 120, 60)
        return .run { send in
            try await Task.sleep(nanoseconds: UInt64(timeToRefresh * 1_000_000_000))
            await send(.refreshTimerTick)
        }
    }
}
