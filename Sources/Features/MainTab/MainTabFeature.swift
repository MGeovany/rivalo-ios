import ComposableArchitecture

/// The signed-in experience: a tab bar hosting the profile and a backend status
/// tab. New tabs (history, activity) compose in here in later phases.
@Reducer
struct MainTabFeature {
    @ObservableState
    struct State: Equatable {
        var profile: ProfileFeature.State
        var serverStatus = ServerStatusFeature.State()
        var selectedTab: Tab = .profile

        enum Tab: Equatable { case status, profile }

        init(accessToken: String) {
            self.profile = ProfileFeature.State(accessToken: accessToken)
        }
    }

    enum Action {
        case profile(ProfileFeature.Action)
        case serverStatus(ServerStatusFeature.Action)
        case selectedTabChanged(State.Tab)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case signOut
        }
    }

    var body: some ReducerOf<Self> {
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

            case .profile, .serverStatus, .delegate:
                return .none
            }
        }
    }
}
