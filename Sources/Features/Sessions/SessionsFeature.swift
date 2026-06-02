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
    }

    enum Action {
        case onAppear
        case listResponse(Result<[SportSession], APIError>)
        case addTapped
        case sessionTapped(SportSession)
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
                state.detail = SessionDetailFeature.State(accessToken: state.accessToken, id: session.id)
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
