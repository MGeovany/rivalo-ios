import ComposableArchitecture
import Foundation

/// Home feed: week activity, latest match, and records promo (Strava-style).
@Reducer
struct SessionsFeature {
    @ObservableState
    struct State: Equatable {
        var accessToken: String
        var sessions: [SportSession] = []
        /// Latest match with samples for map / heatmap on Home.
        var latestSession: SportSession?
        var isLoading = false
        var isLoadingLatest = false
        var errorMessage: String?
        var performancePeriod: PerformancePeriod = .allTime
        @Presents var entry: SessionEntryFeature.State?
        @Presents var detail: SessionDetailFeature.State?
        @Presents var records: RecordsFeature.State?
        /// Top records for the Home promo card.
        var recordHighlights: [RecordEntry] = []
        var activitySearchText: String = ""
        var activityFilter: ActivityListFilter = .all

        var sortedByRecent: [SportSession] {
            sessions.sorted { $0.startedAt > $1.startedAt }
        }

        var recentActivities: [SportSession] {
            Array(sortedByRecent.prefix(20))
        }

        var filteredActivities: [SportSession] {
            let filtered = activityFilter.apply(sortedByRecent)
            let query = activitySearchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !query.isEmpty else { return filtered }
            return filtered.filter { session in
                session.matchesActivitySearch(
                    query,
                    venueName: SessionMetaStore.load(sessionId: session.id).venueName
                )
            }
        }

        var performanceSnapshot: PerformanceSnapshot {
            PerformanceSnapshot.build(from: performancePeriod.filter(sessions))
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case listResponse(Result<[SportSession], APIError>)
        case recordsPreviewResponse(Result<PersonalRecords, APIError>)
        case latestDetailResponse(Result<SportSession, APIError>)
        case addTapped
        case sessionTapped(SportSession)
        case showSummary(SportSession)
        case entry(PresentationAction<SessionEntryFeature.Action>)
        case detail(PresentationAction<SessionDetailFeature.Action>)
        case recordsTapped
        case records(PresentationAction<RecordsFeature.Action>)
    }

    @Dependency(\.apiClient) var apiClient
    @Dependency(\.date) var date

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .onAppear:
                state.isLoading = state.sessions.isEmpty
                state.errorMessage = nil
                let token = state.accessToken
                return .run { send in
                    await send(.listResponse(Result { try await apiClient.listSessions(token) }
                        .mapError { $0 as? APIError ?? .invalidResponse }))
                }

            case let .listResponse(.success(sessions)):
                state.isLoading = false
                state.sessions = sessions
                let token = state.accessToken
                let recordsEffect: Effect<Action> = .run { send in
                    await send(.recordsPreviewResponse(Result {
                        try await apiClient.fetchRecords(token)
                    }.mapError { $0 as? APIError ?? .invalidResponse }))
                }
                guard let latestId = sessions.sorted(by: { $0.startedAt > $1.startedAt }).first?.id else {
                    state.latestSession = nil
                    return .merge(
                        recordsEffect,
                        .run { _ in
                            await PitchesSync.refresh(accessToken: token, apiClient: apiClient)
                            WatchCourtSync.pushCourts(for: sessions)
                            WatchHalftimeAveragesSync.push(from: sessions)
                        }
                    )
                }
                state.isLoadingLatest = true
                return .merge(
                    recordsEffect,
                    .run { _ in
                        await PitchesSync.refresh(accessToken: token, apiClient: apiClient)
                        WatchCourtSync.pushCourts(for: sessions)
                        WatchHalftimeAveragesSync.push(from: sessions)
                    },
                    .run { send in
                        await send(.latestDetailResponse(Result {
                            try await apiClient.getSession(token, latestId)
                        }.mapError { $0 as? APIError ?? .invalidResponse }))
                    }
                )

            case let .recordsPreviewResponse(.success(pr)):
                state.recordHighlights = Array(pr.records.prefix(3))
                return .none

            case .recordsPreviewResponse(.failure):
                return .none

            case .listResponse(.failure):
                state.isLoading = false
                state.errorMessage = "Could not load your sessions."
                return .none

            case let .latestDetailResponse(.success(session)):
                state.isLoadingLatest = false
                state.latestSession = session
                return .none

            case .latestDetailResponse(.failure):
                state.isLoadingLatest = false
                state.latestSession = state.sortedByRecent.first
                return .none

            case .addTapped:
                state.entry = SessionEntryFeature.State(accessToken: state.accessToken)
                return .none

            case let .sessionTapped(session):
                state.detail = SessionDetailFeature.State(accessToken: state.accessToken, id: session.id)
                return .none

            case let .showSummary(session):
                state.detail = SessionDetailFeature.State(
                    accessToken: state.accessToken,
                    id: session.id,
                    session: session
                )
                return .none

            case .recordsTapped:
                state.records = RecordsFeature.State(accessToken: state.accessToken)
                return .none

            case .entry(.presented(.delegate(.created))):
                state.entry = nil
                return .send(.onAppear)

            case .entry(.presented(.delegate(.updated))):
                state.entry = nil
                return .send(.onAppear)

            case .entry(.presented(.delegate(.cancelled))):
                state.entry = nil
                return .none

            case .detail(.presented(.delegate(.dismissed))):
                state.detail = nil
                return .none

            case .detail(.presented(.delegate(.deleted))):
                state.detail = nil
                return .send(.onAppear)

            case let .detail(.presented(.delegate(.requestEdit(session)))):
                state.detail = nil
                state.entry = SessionEntryFeature.State(accessToken: state.accessToken, editing: session)
                return .none

            case .detail(.presented(.delegate(.updated))):
                state.detail = nil
                return .send(.onAppear)

            case .records(.presented(.delegate(.dismissed))):
                state.records = nil
                return .none

            case .entry, .detail, .records:
                return .none
            }
        }
        .ifLet(\.$entry, action: \.entry) {
            SessionEntryFeature()
        }
        .ifLet(\.$detail, action: \.detail) {
            SessionDetailFeature()
        }
        .ifLet(\.$records, action: \.records) {
            RecordsFeature()
        }
    }
}
