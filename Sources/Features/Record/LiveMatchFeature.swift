import ComposableArchitecture
import Foundation
import PostHog

@Reducer
struct LiveMatchFeature {
    @ObservableState
    struct State: Equatable {
        var mode: String = "quick"
        /// Ticks every second on iPhone — derived from startedAt, not received from Watch.
        var elapsedS: Int = 0
        var heartRate: Int = 0
        var distanceM: Double = 0
        var segment: String = "firstHalf"

        // Timestamps from the watch, used to drive the local clock.
        var startedAt: Date?
        var halftimeOffsetS: Int?
        var halftimeStartedAt: Date?

        func computedElapsed(at now: Date) -> Int {
            guard let startedAt else { return elapsedS }
            switch segment {
            case "halftimeBreak":
                let breakStart = halftimeStartedAt ?? startedAt
                return max(0, Int(now.timeIntervalSince(breakStart)))
            case "secondHalf":
                // Show seconds elapsed in the 2nd half.
                let totalSinceStart = max(0, Int(now.timeIntervalSince(startedAt)))
                let offset = halftimeOffsetS ?? 0
                return max(0, totalSinceStart - offset)
            default: // firstHalf
                return max(0, Int(now.timeIntervalSince(startedAt)))
            }
        }
    }

    enum Action: Equatable {
        case liveEventReceived(LiveMatchEvent)
        case timerTick
        case pauseTapped
        case resumeTapped
        case halftimeTapped
        case endTapped
        case commandSent(Bool)
    }

    private enum CancelID { case localTimer }

    @Dependency(\.watchSyncClient) var watchSyncClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .liveEventReceived(event):
                let wasTracking = state.startedAt != nil
                state.mode = event.mode
                state.heartRate = event.heartRate
                state.distanceM = event.distanceM
                state.segment = event.segment
                state.startedAt = event.startedAt
                state.halftimeOffsetS = event.halftimeOffsetS
                state.halftimeStartedAt = event.halftimeStartedAt
                state.elapsedS = state.computedElapsed(at: Date())

                // Start the local 1-second timer on the first event.
                guard !wasTracking else { return .none }
                return .run { send in
                    while true {
                        try await Task.sleep(for: .seconds(1))
                        await send(.timerTick)
                    }
                }
                .cancellable(id: CancelID.localTimer)

            case .timerTick:
                state.elapsedS = state.computedElapsed(at: Date())
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
                let elapsedS = state.elapsedS
                let distanceM = state.distanceM
                return .merge(
                    .cancel(id: CancelID.localTimer),
                    .run { send in
                        PostHogSDK.shared.capture("live_match_ended", properties: [
                            "elapsed_s": elapsedS,
                            "distance_m": distanceM,
                        ])
                        let ok = await watchSyncClient.sendControlCommand(.end)
                        await send(.commandSent(ok))
                    }
                )

            case .commandSent:
                return .none
            }
        }
    }
}
