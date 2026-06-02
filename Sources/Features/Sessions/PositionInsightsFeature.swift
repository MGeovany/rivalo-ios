import ComposableArchitecture
import Foundation

/// Cautious, physical-only comparison across positions (V2-J). Never concludes a
/// "best" position; surfaces an insufficient-data state below the threshold.
@Reducer
struct PositionInsightsFeature {
    @ObservableState
    struct State: Equatable {
        var accessToken: String
        var insights: PositionInsights?
        var isLoading = false
        var errorMessage: String?
    }

    enum Action: Equatable {
        case onAppear
        case loadResponse(Result<PositionInsights, APIError>)
        case dismissTapped
        case delegate(Delegate)

        enum Delegate: Equatable {
            case dismissed
        }
    }

    @Dependency(\.apiClient) var apiClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = state.insights == nil
                state.errorMessage = nil
                let token = state.accessToken
                return .run { send in
                    await send(.loadResponse(Result { try await apiClient.fetchPositionInsights(token) }
                        .mapError { $0 as? APIError ?? .invalidResponse }))
                }

            case let .loadResponse(.success(insights)):
                state.isLoading = false
                state.insights = insights
                return .none

            case .loadResponse(.failure):
                state.isLoading = false
                state.errorMessage = "Could not load position insights."
                return .none

            case .dismissTapped:
                return .send(.delegate(.dismissed))

            case .delegate:
                return .none
            }
        }
    }
}
