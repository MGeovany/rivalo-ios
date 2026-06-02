import ComposableArchitecture
import Foundation

@Reducer
struct RivalriesFeature {
    @ObservableState
    struct State: Equatable {
        var accessToken: String
        var rivalries: [Rivalry] = []
        var isLoading = false
        var errorMessage: String?
    }

    enum Action: Equatable {
        case onAppear
        case loadResponse(Result<[Rivalry], APIError>)
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
                state.isLoading = state.rivalries.isEmpty
                let token = state.accessToken
                return .run { send in
                    await send(.loadResponse(Result { try await apiClient.fetchRivalries(token) }
                        .mapError { $0 as? APIError ?? .invalidResponse }))
                }

            case let .loadResponse(.success(rivalries)):
                state.isLoading = false
                state.rivalries = rivalries
                return .none

            case .loadResponse(.failure):
                state.isLoading = false
                state.errorMessage = "Could not load rivalries."
                return .none

            case .dismissTapped:
                return .send(.delegate(.dismissed))

            case .delegate:
                return .none
            }
        }
    }
}
