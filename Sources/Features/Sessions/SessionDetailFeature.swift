import ComposableArchitecture
import Foundation

/// Loads and displays a single session via `GET /v1/sessions/{id}`.
@Reducer
struct SessionDetailFeature {
    @ObservableState
    struct State: Equatable, Identifiable {
        let accessToken: String
        let id: String
        var session: SportSession?
        var isLoading = false
        var errorMessage: String?
    }

    enum Action: Equatable {
        case onAppear
        case loadResponse(Result<SportSession, APIError>)
    }

    @Dependency(\.apiClient) var apiClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.session == nil else { return .none }
                state.isLoading = true
                let token = state.accessToken
                let id = state.id
                return .run { send in
                    await send(.loadResponse(Result { try await apiClient.getSession(token, id) }
                        .mapError { $0 as? APIError ?? .invalidResponse }))
                }

            case let .loadResponse(.success(session)):
                state.isLoading = false
                state.session = session
                return .none

            case .loadResponse(.failure):
                state.isLoading = false
                state.errorMessage = "Could not load the session."
                return .none
            }
        }
    }
}
