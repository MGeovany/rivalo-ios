import ComposableArchitecture
import Foundation
import PostHog

/// Starts a match on the paired Apple Watch via WatchConnectivity.
@Reducer
struct RecordFeature {
    @ObservableState
    struct State: Equatable {
        let accessToken: String
        var recordAlertMessage: String?
        var lastSetup: iOSMatchSetup?
        var lastSession: SportSession?
        @Presents var liveMatch: LiveMatchFeature.State?
        /// `startedAt` of the match that was just dismissed. Live events for the
        /// same match are ignored so a late `updateApplicationContext` delivery
        /// can't resurrect the live view after the match has ended.
        var endedMatchStartedAt: Date?

        init(accessToken: String) {
            self.accessToken = accessToken
            self.lastSetup = LastSetupStore.load()
        }
    }

    enum Action: Equatable {
        case onAppear
        case lastSessionResponse(Result<SportSession?, APIError>)
        case recordTapped
        case startMatchResponse(StartMatchResult)
        case recordAlertDismissed
        case liveEventReceived(LiveMatchEvent)
        case dismissLiveMatch
        case liveMatch(PresentationAction<LiveMatchFeature.Action>)
    }

    @Dependency(\.watchSyncClient) var watchSyncClient
    @Dependency(\.apiClient) var apiClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.lastSetup = LastSetupStore.load()
                let token = state.accessToken
                return .run { send in
                    await send(.lastSessionResponse(Result {
                        let sessions = try await apiClient.listSessions(token)
                        return sessions.max(by: { $0.startedAt < $1.startedAt })
                    }.mapError { $0 as? APIError ?? .invalidResponse }))
                }

            case let .lastSessionResponse(.success(session)):
                state.lastSession = session
                return .none

            case .lastSessionResponse(.failure):
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
                        "Abre Rivalo en tu Apple Watch — tu partido está listo para empezar."
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
                // Ignore stale events from a match that already ended — otherwise
                // a delayed updateApplicationContext re-presents the live view.
                if event.startedAt == state.endedMatchStartedAt {
                    return .none
                }
                if state.liveMatch == nil {
                    state.liveMatch = LiveMatchFeature.State()
                }
                return .send(.liveMatch(.presented(.liveEventReceived(event))))

            case .dismissLiveMatch:
                if let started = state.liveMatch?.startedAt {
                    state.endedMatchStartedAt = started
                }
                state.liveMatch = nil
                return .none

            case .recordAlertDismissed:
                state.recordAlertMessage = nil
                return .none

            case .liveMatch(.presented(.endTapped)):
                if let started = state.liveMatch?.startedAt {
                    state.endedMatchStartedAt = started
                }
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
