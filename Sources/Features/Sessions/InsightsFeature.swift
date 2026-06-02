import ComposableArchitecture
import Foundation

@Reducer
struct InsightsFeature {
    @ObservableState
    struct State: Equatable {
        var accessToken: String
        var insights: SessionInsights?
        var isLoading = false
        var errorMessage: String?
    }

    enum Action: Equatable {
        case onAppear
        case loadResponse(Result<SessionInsights, APIError>)
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
                    await send(.loadResponse(Result {
                        try await apiClient.fetchInsights(token)
                    }.mapError { $0 as? APIError ?? .invalidResponse }))
                }

            case let .loadResponse(.success(ins)):
                state.isLoading = false
                state.insights = ins
                return .none

            case .loadResponse(.failure):
                state.isLoading = false
                state.errorMessage = "Could not load insights."
                return .none
            }
        }
    }
}
