import ComposableArchitecture

/// Signed-in tab bar: Home, Record, You, Activities, and Plan.
@Reducer
struct MainTabFeature {
    @ObservableState
    struct State: Equatable {
        let accessToken: String
        var sessions: SessionsFeature.State
        var record = RecordFeature.State()
        var profile: ProfileFeature.State
        var selectedTab: Tab = .home

        enum Tab: Equatable {
            case home
            case record
            case you
            case activities
            case plan
        }

        init(accessToken: String) {
            self.accessToken = accessToken
            self.sessions = SessionsFeature.State(accessToken: accessToken)
            self.profile = ProfileFeature.State(accessToken: accessToken)
        }
    }

    enum Action {
        case task
        case watchSessionsChanged
        case watchSessionUploaded(SportSession)
        case sessions(SessionsFeature.Action)
        case record(RecordFeature.Action)
        case profile(ProfileFeature.Action)
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
        Scope(state: \.record, action: \.record) {
            RecordFeature()
        }
        Scope(state: \.profile, action: \.profile) {
            ProfileFeature()
        }

        Reduce { state, action in
            switch action {
            case .task:
                let token = state.accessToken
                let api = apiClient
                let queue = pendingSessions
                let watch = watchSyncClient
                return .run { send in
                    for item in queue.all() {
                        if (try? await api.createSession(token, item.payload)) != nil {
                            queue.remove(item.id)
                            await send(.watchSessionsChanged)
                        }
                    }
                    for await received in watch.incomingSessions() {
                        let queued = queue.enqueue(received)
                        if let created = try? await api.createSession(token, received) {
                            queue.remove(queued.id)
                            await send(.watchSessionUploaded(created))
                        }
                    }
                }

            case .watchSessionsChanged:
                return .send(.sessions(.onAppear))

            case let .watchSessionUploaded(created):
                state.selectedTab = .home
                return .merge(
                    .send(.sessions(.onAppear)),
                    .send(.sessions(.showSummary(created)))
                )

            case .profile(.delegate(.signOut)):
                return .send(.delegate(.signOut))

            case let .selectedTabChanged(tab):
                state.selectedTab = tab
                return .none

            case .sessions, .record, .profile, .delegate:
                return .none
            }
        }
    }
}
