import ComposableArchitecture

/// The signed-in experience: a tab bar hosting the profile and a backend status
/// tab. New tabs (history, activity) compose in here in later phases.
@Reducer
struct MainTabFeature {
    @ObservableState
    struct State: Equatable {
        var sessions: SessionsFeature.State
        var profile: ProfileFeature.State
        var serverStatus = ServerStatusFeature.State()
        var selectedTab: Tab = .sessions

        enum Tab: Equatable { case sessions, profile, status }

        init(accessToken: String) {
            self.sessions = SessionsFeature.State(accessToken: accessToken)
            self.profile = ProfileFeature.State(accessToken: accessToken)
        }
    }

    enum Action {
        case sessions(SessionsFeature.Action)
        case profile(ProfileFeature.Action)
        case serverStatus(ServerStatusFeature.Action)
        case selectedTabChanged(State.Tab)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case signOut
        }
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.sessions, action: \.sessions) {
            SessionsFeature()
        }
        Scope(state: \.profile, action: \.profile) {
            ProfileFeature()
        }
        Scope(state: \.serverStatus, action: \.serverStatus) {
            ServerStatusFeature()
        }

        Reduce { state, action in
            switch action {
            case .profile(.delegate(.signOut)):
                return .send(.delegate(.signOut))

            case let .selectedTabChanged(tab):
                state.selectedTab = tab
                return .none

            case .sessions, .profile, .serverStatus, .delegate:
                return .none
            }
        }
    }
}
