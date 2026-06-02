import ComposableArchitecture

/// The signed-in experience: a tab bar hosting the profile and a backend status
/// tab. New tabs (history, activity) compose in here in later phases.
@Reducer
struct MainTabFeature {
    @ObservableState
    struct State: Equatable {
        let accessToken: String
        var sessions: SessionsFeature.State
        var profile: ProfileFeature.State
        var serverStatus = ServerStatusFeature.State()
        var selectedTab: Tab = .sessions

        enum Tab: Equatable { case sessions, profile, status }

        init(accessToken: String) {
            self.accessToken = accessToken
            self.sessions = SessionsFeature.State(accessToken: accessToken)
            self.profile = ProfileFeature.State(accessToken: accessToken)
        }
    }

    enum Action {
        case task
        case watchSessionUploaded
        case sessions(SessionsFeature.Action)
        case profile(ProfileFeature.Action)
        case serverStatus(ServerStatusFeature.Action)
        case selectedTabChanged(State.Tab)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case signOut
        }
    }

    @Dependency(\.apiClient) var apiClient
    @Dependency(\.watchSyncClient) var watchSyncClient
    @Dependency(\.pendingSessions) var pendingSessions

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
            case .task:
                // Flush any sessions queued while offline, then keep uploading
                // sessions as they arrive from the watch.
                let token = state.accessToken
                let api = apiClient
                let queue = pendingSessions
                let watch = watchSyncClient
                return .run { send in
                    for item in queue.all() {
                        if (try? await api.createSession(token, item.payload)) != nil {
                            queue.remove(item.id)
                            await send(.watchSessionUploaded)
                        }
                    }
                    for await received in watch.incomingSessions() {
                        let queued = queue.enqueue(received)
                        if (try? await api.createSession(token, received)) != nil {
                            queue.remove(queued.id)
                            await send(.watchSessionUploaded)
                        }
                    }
                }

            case .watchSessionUploaded:
                // A watch session reached the backend; refresh the list.
                return .send(.sessions(.onAppear))

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
