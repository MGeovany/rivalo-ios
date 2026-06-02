import ComposableArchitecture
import Foundation

/// Post-match context form that appears after finishing a session and is editable from the detail.
@Reducer
struct MatchContextFeature {
    @ObservableState
    struct State: Equatable {
        let sessionId: String
        var accessToken: String

        var matchType: String = ""
        var surface: String = ""
        var position: String = ""
        var result: String = ""
        var feeling: Int = 3
        var matchTag: String = ""
        var isSaving = false
        var errorMessage: String?
        var savedSuccessfully = false

        var canSave: Bool {
            !isSaving
        }
    }

    enum Action: Equatable {
        case setMatchType(String)
        case setSurface(String)
        case setPosition(String)
        case setResult(String)
        case setFeeling(Int)
        case setMatchTag(String)
        case saveTapped
        case saveResponse(Result<SportSession, APIError>)
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
            case let .setMatchType(v):
                state.matchType = v
                return .none
            case let .setSurface(v):
                state.surface = v
                return .none
            case let .setPosition(v):
                state.position = v
                return .none
            case let .setResult(v):
                state.result = v
                return .none
            case let .setFeeling(v):
                state.feeling = v
                return .none
            case let .setMatchTag(v):
                state.matchTag = v
                return .none

            case .saveTapped:
                guard state.canSave else { return .none }
                state.isSaving = true
                state.errorMessage = nil
                let feeling = state.feeling
                let update = SessionContextUpdate(
                    matchType: state.matchType.isEmpty ? nil : state.matchType,
                    surface: state.surface.isEmpty ? nil : state.surface,
                    position: state.position.isEmpty ? nil : state.position,
                    result: state.result.isEmpty ? nil : state.result,
                    feeling: feeling,
                    matchTag: state.matchTag.isEmpty ? nil : state.matchTag,
                    pitchId: nil
                )
                let token = state.accessToken
                let id = state.sessionId
                return .run { send in
                    await send(.saveResponse(Result {
                        try await apiClient.patchSessionContext(token, id, update)
                    }.mapError { $0 as? APIError ?? .invalidResponse }))
                }

            case .saveResponse(.success):
                state.isSaving = false
                state.savedSuccessfully = true
                return .send(.delegate(.dismissed))

            case .saveResponse(.failure):
                state.isSaving = false
                state.errorMessage = "Could not save match context."
                return .none

            case .dismissTapped:
                return .send(.delegate(.dismissed))

            case .delegate:
                return .none
            }
        }
    }
}
