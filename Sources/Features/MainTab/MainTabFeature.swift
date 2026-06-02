import ComposableArchitecture

/// Signed-in tab bar: Home, Record, You, Activities, and Plan.
@Reducer
struct MainTabFeature {
    @ObservableState
    struct State: Equatable {
        var accessToken: String
        var sessions: SessionsFeature.State
        var record = RecordFeature.State()
        var profile: ProfileFeature.State
        var selectedTab: Tab = .home
        @Presents var pitchMeasure: PitchMeasureFeature.State?

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
        case openPitchMeasure(PitchMeasurementMethod)
        case pitchMeasure(PresentationAction<PitchMeasureFeature.Action>)
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
        .ifLet(\.$pitchMeasure, action: \.pitchMeasure) {
            PitchMeasureFeature()
        }

        Reduce { state, action in
            switch action {
            case .task:
                let token = state.accessToken
                let api = apiClient
                let queue = pendingSessions
                let watch = watchSyncClient
                return .run { send in
                    await PitchesSync.refresh(accessToken: token, apiClient: api)
                    for item in queue.all() {
                        if let created = try? await WatchSessionUpload.createFromWatch(
                            accessToken: token,
                            payload: item.payload,
                            apiClient: api
                        ) {
                            queue.remove(item.id)
                            await send(.watchSessionUploaded(created))
                        }
                    }
                    await withDiscardingTaskGroup { group in
                        group.addTask {
                            for await received in watch.incomingSessions() {
                                let queued = queue.enqueue(received)
                                if let created = try? await WatchSessionUpload.createFromWatch(
                                    accessToken: token,
                                    payload: received,
                                    apiClient: api
                                ) {
                                    queue.remove(queued.id)
                                    await send(.watchSessionUploaded(created))
                                }
                            }
                        }
                        group.addTask {
                            for await method in watch.incomingMeasureCourt() {
                                await send(.openPitchMeasure(method))
                            }
                        }
                        group.addTask {
                            for await event in watch.liveMatchEvents() {
                                await send(.record(.liveEventReceived(event)))
                            }
                        }
                    }
                }

            case let .openPitchMeasure(method):
                state.pitchMeasure = PitchMeasureFeature.State(
                    accessToken: state.accessToken,
                    prefill: method
                )
                return .none

            case .pitchMeasure(.presented(.delegate(.dismissed))):
                state.pitchMeasure = nil
                return .none

            case .pitchMeasure:
                return .none

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
                switch tab {
                case .home:
                    return .send(.sessions(.onAppear))
                case .you:
                    return .send(.profile(.onAppear))
                case .record, .activities, .plan:
                    return .none
                }

            case .record(.delegate(.openMeasureCourt)):
                state.pitchMeasure = PitchMeasureFeature.State(accessToken: state.accessToken)
                return .none

            case .sessions, .record, .profile, .delegate:
                return .none
            }
        }
    }
}
