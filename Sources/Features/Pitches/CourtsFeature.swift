import ComposableArchitecture
import Foundation

/// Lists the user's courts and presents create/edit.
@Reducer
struct CourtsFeature {
    @ObservableState
    struct State: Equatable {
        var accessToken: String
        var pitches: [Pitch] = []
        var isLoading = false
        var errorMessage: String?
        @Presents var edit: CourtEditFeature.State?
    }

    enum Action: Equatable {
        case onAppear
        case listResponse(Result<[Pitch], APIError>)
        case addTapped
        case courtTapped(Pitch)
        case dismissTapped
        case edit(PresentationAction<CourtEditFeature.Action>)
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
                state.isLoading = state.pitches.isEmpty
                let token = state.accessToken
                return .run { send in
                    await send(.listResponse(Result { try await apiClient.listPitches(token) }
                        .mapError { $0 as? APIError ?? .invalidResponse }))
                }

            case let .listResponse(.success(pitches)):
                state.isLoading = false
                state.pitches = pitches
                return .none

            case .listResponse(.failure):
                state.isLoading = false
                state.errorMessage = "Could not load your courts."
                return .none

            case .addTapped:
                state.edit = CourtEditFeature.State(accessToken: state.accessToken)
                return .none

            case let .courtTapped(pitch):
                state.edit = CourtEditFeature.State(accessToken: state.accessToken, pitch: pitch)
                return .none

            case .edit(.presented(.delegate(.saved))),
                 .edit(.presented(.delegate(.deleted))):
                state.edit = nil
                return .send(.onAppear)

            case .edit(.presented(.delegate(.dismissed))):
                state.edit = nil
                return .none

            case .edit:
                return .none

            case .dismissTapped:
                return .send(.delegate(.dismissed))

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$edit, action: \.edit) {
            CourtEditFeature()
        }
    }
}
