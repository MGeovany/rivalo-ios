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
    }

    enum Action: Equatable {
        case onAppear
        case loadResponse(Result<PersonalRecords, APIError>)
        case recordTapped(RecordEntry)
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

            case .recordTapped:
                return .none
            }
        }
    }
}
