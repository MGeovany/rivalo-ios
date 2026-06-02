import ComposableArchitecture
import Foundation

@Reducer
struct LiveMatchFeature {
    @ObservableState
    struct State: Equatable {
        var mode: String = "quick"
        var elapsedS: Int = 0
        var heartRate: Int = 0
        var distanceM: Double = 0
        var segment: String = "firstHalf"
    }

    enum Action: Equatable {
        case liveEventReceived(LiveMatchEvent)
        case pauseTapped
        case resumeTapped
        case halftimeTapped
        case endTapped
        case commandSent(Bool)
    }

    @Dependency(\.watchSyncClient) var watchSyncClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .liveEventReceived(event):
                state.mode = event.mode
                state.elapsedS = event.elapsedS
                state.heartRate = event.heartRate
                state.distanceM = event.distanceM
                state.segment = event.segment
                return .none

            case .pauseTapped:
                return .run { send in
                    let ok = await watchSyncClient.sendControlCommand(.pause)
                    await send(.commandSent(ok))
                }

            case .resumeTapped:
                return .run { send in
                    let ok = await watchSyncClient.sendControlCommand(.resume)
                    await send(.commandSent(ok))
                }

            case .halftimeTapped:
                return .run { send in
                    let ok = await watchSyncClient.sendControlCommand(.halftime)
                    await send(.commandSent(ok))
                }

            case .endTapped:
                return .run { send in
                    let ok = await watchSyncClient.sendControlCommand(.end)
                    await send(.commandSent(ok))
                }

            case .commandSent:
                return .none
            }
        }
    }
}
