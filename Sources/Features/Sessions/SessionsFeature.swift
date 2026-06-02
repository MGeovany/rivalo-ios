import ComposableArchitecture
import Foundation

/// Lists the user's sessions and hosts the manual-entry form and the detail view.
@Reducer
struct SessionsFeature {
    @ObservableState
    struct State: Equatable {
        let accessToken: String
        var sessions: [SportSession] = []
        var isLoading = false
        var errorMessage: String?
        @Presents var entry: SessionEntryFeature.State?
        @Presents var detail: SessionDetailFeature.State?

        /// Average distance (km) across sessions, for the comparative header.
        var averageDistanceKm: Double? {
            guard !sessions.isEmpty else { return nil }
            return sessions.reduce(0) { $0 + $1.distanceM } / Double(sessions.count) / 1000
        }

        /// Average duration (minutes) across sessions.
        var averageDurationMin: Int? {
            guard !sessions.isEmpty else { return nil }
            return sessions.reduce(0) { $0 + $1.durationS } / sessions.count / 60
        }
    }

    enum Action {
        case onAppear
        case listResponse(Result<[SportSession], APIError>)
        case addTapped
        case sessionTapped(SportSession)
        case showSummary(SportSession)
        case entry(PresentationAction<SessionEntryFeature.Action>)
        case detail(PresentationAction<SessionDetailFeature.Action>)
    }

    @Dependency(\.apiClient) var apiClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                let token = state.accessToken
                return .run { send in
                    await send(.listResponse(Result { try await apiClient.listSessions(token) }
                        .mapError { $0 as? APIError ?? .invalidResponse }))
                }

            case let .listResponse(.success(sessions)):
                state.isLoading = false
                state.sessions = sessions
                return .none

            case .listResponse(.failure):
                state.isLoading = false
                state.errorMessage = "Could not load your sessions."
                return .none

            case .addTapped:
                state.entry = SessionEntryFeature.State(accessToken: state.accessToken)
                return .none

            case let .sessionTapped(session):
                // Open by id so the detail validates GET /v1/sessions/{id}.
                state.detail = SessionDetailFeature.State(accessToken: state.accessToken, id: session.id)
                return .none

            case let .showSummary(session):
                // Auto-presented after a watch session syncs: we already have it.
                state.detail = SessionDetailFeature.State(
                    accessToken: state.accessToken,
                    id: session.id,
                    session: session
                )
                return .none

            case .entry(.presented(.delegate(.created))):
                state.entry = nil
                return .send(.onAppear)

            case .entry(.presented(.delegate(.cancelled))):
                state.entry = nil
                return .none

            case .entry, .detail:
                return .none
            }
        }
        .ifLet(\.$entry, action: \.entry) {
            SessionEntryFeature()
        }
        .ifLet(\.$detail, action: \.detail) {
            SessionDetailFeature()
        }
    }
}
