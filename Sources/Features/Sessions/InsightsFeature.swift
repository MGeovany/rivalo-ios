import ComposableArchitecture
import Foundation

@Reducer
struct InsightsFeature {
    @ObservableState
    struct State: Equatable {
        var accessToken: String
        var insights: SessionInsights?
        var recentSessions: [SportSession] = []
        var isLoading = false
        var errorMessage: String?
    }

    enum Action: Equatable {
        case onAppear
        case loadResponse(Result<SessionInsights, APIError>)
        case sessionsResponse(Result<[SportSession], APIError>)
    }

    @Dependency(\.apiClient) var apiClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                let token = state.accessToken
                return .merge(
                    .run { send in
                        await send(.loadResponse(Result {
                            try await apiClient.fetchInsights(token)
                        }.mapError { $0 as? APIError ?? .invalidResponse }))
                    },
                    .run { send in
                        await send(.sessionsResponse(Result {
                            try await apiClient.listSessions(token)
                        }.mapError { $0 as? APIError ?? .invalidResponse }))
                    }
                )

            case let .loadResponse(.success(ins)):
                state.isLoading = false
                state.insights = ins
                return .none

            case .loadResponse(.failure):
                state.isLoading = false
                state.errorMessage = "Could not load insights."
                return .none

            case let .sessionsResponse(.success(sessions)):
                state.recentSessions = sessions.sorted { $0.startedAt > $1.startedAt }
                return .none

            case .sessionsResponse(.failure):
                return .none
            }
        }
    }
}
