import ComposableArchitecture
import Foundation

/// Loads the achievement badge catalog with the user's progress.
@Reducer
struct BadgesFeature {
    @ObservableState
    struct State: Equatable {
        var accessToken: String
        var badges: [Badge] = []
        var isLoading = false
        var errorMessage: String?

        var earned: [Badge] { badges.filter(\.earned) }
        var pending: [Badge] { badges.filter { !$0.earned } }
    }

    enum Action: Equatable {
        case onAppear
        case loadResponse(Result<[Badge], APIError>)
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
                state.isLoading = state.badges.isEmpty
                let token = state.accessToken
                return .run { send in
                    await send(.loadResponse(Result { try await apiClient.fetchBadges(token) }
                        .mapError { $0 as? APIError ?? .invalidResponse }))
                }

            case let .loadResponse(.success(badges)):
                state.isLoading = false
                state.badges = badges
                return .none

            case .loadResponse(.failure):
                state.isLoading = false
                state.errorMessage = "Could not load your badges."
                return .none

            case .dismissTapped:
                return .send(.delegate(.dismissed))

            case .delegate:
                return .none
            }
        }
    }
}
