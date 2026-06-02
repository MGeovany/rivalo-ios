import ComposableArchitecture
import Foundation

@Reducer
struct RecordsFeature {
    @ObservableState
    struct State: Equatable {
        var accessToken: String
        var records: [RecordEntry] = []
        var isLoading = false
        var errorMessage: String?
        @Presents var detail: SessionDetailFeature.State?
    }

    enum Action: Equatable {
        case onAppear
        case loadResponse(Result<PersonalRecords, APIError>)
        case dismissTapped
        case recordTapped(RecordEntry)
        case detail(PresentationAction<SessionDetailFeature.Action>)
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
                state.isLoading = true
                state.errorMessage = nil
                let token = state.accessToken
                return .run { send in
                    await send(.loadResponse(Result {
                        try await apiClient.fetchRecords(token)
                    }.mapError { $0 as? APIError ?? .invalidResponse }))
                }

            case let .loadResponse(.success(pr)):
                state.isLoading = false
                state.records = pr.records
                return .none

            case .loadResponse(.failure):
                state.isLoading = false
                state.errorMessage = "Could not load records."
                return .none

            case .dismissTapped:
                return .send(.delegate(.dismissed))

            case let .recordTapped(record):
                guard !record.sessionId.isEmpty else { return .none }
                state.detail = SessionDetailFeature.State(
                    accessToken: state.accessToken,
                    id: record.sessionId
                )
                return .none

            case .detail(.presented(.delegate(.dismissed))):
                state.detail = nil
                return .none

            case .detail(.presented(.delegate(.deleted))):
                state.detail = nil
                return .send(.onAppear)

            case let .detail(.presented(.delegate(.requestEdit(session)))):
                state.detail = nil
                return .none

            case .detail(.presented(.delegate(.updated))):
                state.detail = nil
                return .send(.onAppear)

            case .detail:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$detail, action: \.detail) {
            SessionDetailFeature()
        }
    }
}
