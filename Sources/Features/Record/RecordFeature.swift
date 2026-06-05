import ComposableArchitecture
import PostHog

/// Starts a match on the paired Apple Watch via WatchConnectivity.
@Reducer
struct RecordFeature {
    @ObservableState
    struct State: Equatable {
        var recordAlertMessage: String?
        var lastSetup: iOSMatchSetup?
        @Presents var liveMatch: LiveMatchFeature.State?

        init() {
            self.lastSetup = LastSetupStore.load()
        }
    }

    enum Action: Equatable {
        case onAppear
        case recordTapped
        case startMatchResponse(StartMatchResult)
        case recordAlertDismissed
        case liveEventReceived(LiveMatchEvent)
        case dismissLiveMatch
        case liveMatch(PresentationAction<LiveMatchFeature.Action>)
    }

    @Dependency(\.watchSyncClient) var watchSyncClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.lastSetup = LastSetupStore.load()
                return .none

            case .recordTapped:
                return .run { send in
                    let result = await watchSyncClient.startMatch()
                    await send(.startMatchResponse(result))
                }

            case let .startMatchResponse(result):
                switch result {
                case .started:
                    state.recordAlertMessage = nil
                    return .run { _ in
                        PostHogSDK.shared.capture("match_start_requested", properties: [
                            "result": "started",
                        ])
                    }
                case .queued:
                    state.recordAlertMessage =
                        "Open Rivalo on your Apple Watch — your match is ready to start."
                    return .run { _ in
                        PostHogSDK.shared.capture("match_start_requested", properties: [
                            "result": "queued",
                        ])
                    }
                case let .unavailable(message):
                    state.recordAlertMessage = message
                    return .run { _ in
                        PostHogSDK.shared.capture("match_start_requested", properties: [
                            "result": "unavailable",
                            "reason": message,
                        ])
                    }
                }

            case let .liveEventReceived(event):
                if state.liveMatch == nil {
                    state.liveMatch = LiveMatchFeature.State()
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
            }
        }
        .ifLet(\.$liveMatch, action: \.liveMatch) {
            LiveMatchFeature()
        }
    }
}
