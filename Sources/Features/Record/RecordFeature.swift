import ComposableArchitecture

/// Starts a match on the paired Apple Watch via WatchConnectivity.
@Reducer
struct RecordFeature {
    @ObservableState
    struct State: Equatable {
        var recordAlertMessage: String?
    }

    enum Action: Equatable {
        case recordTapped
        case startMatchResponse(StartMatchResult)
        case recordAlertDismissed
    }

    @Dependency(\.watchSyncClient) var watchSyncClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .recordTapped:
                return .run { send in
                    let result = await watchSyncClient.startMatch()
                    await send(.startMatchResponse(result))
                }

            case let .startMatchResponse(result):
                switch result {
                case .started:
                    state.recordAlertMessage = nil
                    return .none
                case .queued:
                    state.recordAlertMessage =
                        "Open Rivalo on your Apple Watch — your match is ready to start."
                    return .none
                case let .unavailable(message):
                    state.recordAlertMessage = message
                    return .none
                }

            case .recordAlertDismissed:
                state.recordAlertMessage = nil
                return .none
            }
        }
    }
}
