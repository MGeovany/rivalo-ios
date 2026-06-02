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
    }

    enum Action {
        case onAppear
        case sessionLoaded(Session?)
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
                    guard stored.isExpired else {
                        await send(.sessionLoaded(stored))
                        return
                    }
                    // Access token expired: try to refresh, else fall back to login.
                    do {
                        let refreshed = try await authClient.refresh(stored.refreshToken)
                        try? tokenStore.save(refreshed)
                        await send(.sessionLoaded(refreshed))
                    } catch {
                        tokenStore.clear()
                        await send(.sessionLoaded(nil))
                    }
                }

            case let .sessionLoaded(session):
                state.isLoading = false
                state.main = session.map { MainTabFeature.State(accessToken: $0.accessToken) }
                return .none

            case let .auth(.delegate(.authenticated(session))):
                state.auth = AuthenticationFeature.State()
                state.main = MainTabFeature.State(accessToken: session.accessToken)
                return .run { _ in try? tokenStore.save(session) }

            case .main(.delegate(.signOut)):
                let accessToken = state.main?.profile.accessToken
                state.main = nil
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
}
