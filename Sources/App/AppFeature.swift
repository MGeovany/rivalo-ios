import ComposableArchitecture

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
                    return startRefreshTimer(session)
                }
                return .none

            case .refreshTimerTick:
                return .run { [refreshToken = state.refreshToken] send in
                    let token = tokenStore.load()?.refreshToken ?? refreshToken
                    guard let token else { return }
                    let result = await Result {
                        try await authClient.refresh(token)
                    }.mapError { $0 as? AuthError ?? .invalidResponse }
                    await send(.tokenRefreshed(result))
                }

            case let .tokenRefreshed(.success(session)):
                state.refreshToken = session.refreshToken
                state.main?.accessToken = session.accessToken
                state.main?.sessions.accessToken = session.accessToken
                state.main?.profile.accessToken = session.accessToken
                try? tokenStore.save(session)
                return startRefreshTimer(session)

            case .tokenRefreshed(.failure):
                return .none

            case let .auth(.delegate(.authenticated(session))):
                state.auth = AuthenticationFeature.State()
                state.refreshToken = session.refreshToken
                state.main = MainTabFeature.State(accessToken: session.accessToken)
                try? tokenStore.save(session)
                return startRefreshTimer(session)

            case .main(.delegate(.signOut)):
                let accessToken = state.main?.profile.accessToken
                state.main = nil
                state.refreshToken = nil
                return .run { _ in
                    tokenStore.clear()
                    if let accessToken {
                        try? await authClient.signOut(accessToken)
                    }
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
