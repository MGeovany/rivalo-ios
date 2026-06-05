import ComposableArchitecture
import PostHog

/// Signed-in tab bar: Home, Record, You, Activities, and Insights.
@Reducer
struct MainTabFeature {
    @ObservableState
    struct State: Equatable {
        var accessToken: String
        var sessions: SessionsFeature.State
        var record = RecordFeature.State()
        var profile: ProfileFeature.State
        var insights: InsightsFeature.State
        var selectedTab: Tab = .home

        enum Tab: Equatable {
            case home
            case record
            case you
            case activities
            case insights
        }

        init(accessToken: String) {
            self.accessToken = accessToken
            self.sessions = SessionsFeature.State(accessToken: accessToken)
            self.profile = ProfileFeature.State(accessToken: accessToken)
            self.insights = InsightsFeature.State(accessToken: accessToken)
        }
    }

    enum Action {
        case task
        case watchSessionsChanged
        case watchSessionUploaded(SportSession)
        case openSessionFromNotification(MatchOpenEvent)
        case sessions(SessionsFeature.Action)
        case record(RecordFeature.Action)
        case profile(ProfileFeature.Action)
        case insights(InsightsFeature.Action)
        case selectedTabChanged(State.Tab)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case signOut
            case accountDeleted
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
        Scope(state: \.insights, action: \.insights) {
            InsightsFeature()
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
                        do {
                            let created = try await WatchSessionUpload.createFromWatch(
                                accessToken: token,
                                payload: item.payload,
                                apiClient: api
                            )
                            queue.remove(item.id)
                            await send(.watchSessionUploaded(created))
                        } catch {
                            PostHogAnalytics.matchSaveFromWatchFailed(error: error.localizedDescription)
                        }
                    }
                    await withDiscardingTaskGroup { group in
                        group.addTask {
                            for await received in watch.incomingSessions() {
                                let queued = queue.enqueue(received)
                                do {
                                    let created = try await WatchSessionUpload.createFromWatch(
                                        accessToken: token,
                                        payload: received,
                                        apiClient: api
                                    )
                                    queue.remove(queued.id)
                                    await send(.watchSessionUploaded(created))
                                } catch {
                                    PostHogAnalytics.matchSaveFromWatchFailed(error: error.localizedDescription)
                                }
                            }
                        }
                        group.addTask {
                            for await event in watch.liveMatchEvents() {
                                await send(.record(.liveEventReceived(event)))
                            }
                        }
                        group.addTask {
                            for await open in MatchNotifications.shared.events() {
                                await send(.openSessionFromNotification(open))
                            }
                        }
                    }
                }

            case .watchSessionsChanged:
                return .send(.sessions(.onAppear))

            case let .watchSessionUploaded(created):
                state.selectedTab = .home
                let summaryBody = "\(created.distanceKmText) · \(created.durationText)"
                    + (created.matchRating.map { String(format: " · rating %.0f", $0) } ?? "")
                return .merge(
                    .send(.sessions(.onAppear)),
                    .send(.sessions(.showSummary(created))),
                    .run { _ in
                        PostHogAnalytics.matchSavedFromWatch(
                            durationS: created.durationS,
                            distanceM: created.distanceM ?? 0,
                            rating: created.matchRating
                        )
                        MatchNotifications.shared.scheduleSummary(
                            sessionId: created.id,
                            title: "Match saved ⚽️",
                            body: summaryBody
                        )
                        MatchNotifications.shared.scheduleResultReminder(sessionId: created.id)
                    }
                )

            case let .openSessionFromNotification(open):
                state.selectedTab = .home
                return .merge(
                    .send(.sessions(.onAppear)),
                    .send(.sessions(.openSession(open.sessionId, open.openResult)))
                )

            case .profile(.delegate(.signOut)):
                return .send(.delegate(.signOut))

            case .profile(.delegate(.accountDeleted)):
                return .send(.delegate(.accountDeleted))

            case let .selectedTabChanged(tab):
                state.selectedTab = tab
                switch tab {
                case .home:
                    return .send(.sessions(.onAppear))
                case .you:
                    return .send(.profile(.onAppear))
                case .insights:
                    return .send(.insights(.onAppear))
                case .activities:
                    return .send(.sessions(.onAppear))
                case .record:
                    return .none
                }

            case .sessions, .record, .profile, .insights, .delegate:
                return .none
            }
        }
    }
}
