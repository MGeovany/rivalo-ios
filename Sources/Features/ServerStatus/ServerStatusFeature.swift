import ComposableArchitecture
import Foundation

/// Feature that checks and displays backend connectivity via `/health`.
/// Used in Phase 1 to validate end-to-end wiring between the app and the server.
@Reducer
struct ServerStatusFeature {
    @ObservableState
    struct State: Equatable {
        var connection: Connection = .idle

        enum Connection: Equatable {
            case idle
            case checking
            case online(database: String)
            case offline(message: String)
        }
    }

    enum Action: Equatable {
        case onAppear
        case checkTapped
        case healthResponse(Result<HealthStatus, APIError>)
    }

    @Dependency(\.apiClient) var apiClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear, .checkTapped:
                state.connection = .checking
                return .run { send in
                    do {
                        let status = try await apiClient.health()
                        await send(.healthResponse(.success(status)))
                    } catch let error as APIError {
                        await send(.healthResponse(.failure(error)))
                    } catch {
                        await send(.healthResponse(.failure(.invalidResponse)))
                    }
                }

            case let .healthResponse(.success(status)):
                state.connection = .online(database: status.database)
                return .none

            case .healthResponse(.failure):
                state.connection = .offline(message: "Could not reach the server")
                return .none
            }
        }
    }
}
