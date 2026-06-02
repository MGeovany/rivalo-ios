import ComposableArchitecture

/// Starts a match on the paired Apple Watch via WatchConnectivity.
@Reducer
struct RecordFeature {
    @ObservableState
    struct State: Equatable {
        var recordAlertMessage: String?
        @Presents var liveMatch: LiveMatchFeature.State?
    }

    enum Action: Equatable {
        case recordTapped
        case measureCourtTapped
        case startMatchResponse(StartMatchResult)
        case recordAlertDismissed
        case liveEventReceived(LiveMatchEvent)
        case dismissLiveMatch
        case liveMatch(PresentationAction<LiveMatchFeature.Action>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case openMeasureCourt
        }
    }

    @Dependency(\.watchSyncClient) var watchSyncClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .measureCourtTapped:
                return .send(.delegate(.openMeasureCourt))

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

            case let .liveEventReceived(event):
                if state.liveMatch == nil {
                    state.liveMatch = LiveMatchFeature.State(
                        mode: event.mode,
                        elapsedS: event.elapsedS,
                        heartRate: event.heartRate,
                        distanceM: event.distanceM,
                        segment: event.segment
                    )
                }
                return .send(.liveMatch(.presented(.liveEventReceived(event))))

            case .dismissLiveMatch:
                state.liveMatch = nil
                return .none

            case .recordAlertDismissed:
                state.recordAlertMessage = nil
                return .none

            case .liveMatch(.presented(.endTapped)):
                state.liveMatch = nil
                return .none

            case .liveMatch:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$liveMatch, action: \.liveMatch) {
            LiveMatchFeature()
        }
    }
}
