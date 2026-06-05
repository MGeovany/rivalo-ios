import ComposableArchitecture
import Foundation
import PostHog

/// hub: measure on Apple Watch (walk); manual is watch-only.
@Reducer
struct PitchMeasureFeature {
    @ObservableState
    struct State: Equatable {
        var accessToken: String
        var route: Route = .hub

        enum Route: Equatable {
            case hub
            case walk
        }

        init(accessToken: String, prefill: PitchMeasurementMethod? = nil) {
            self.accessToken = accessToken
            if prefill == .walk {
                route = .walk
            }
        }
    }

    enum Action: Equatable {
        case methodSelected(PitchMeasurementMethod)
        case backToHub
        case dismissTapped
        case delegate(Delegate)

        enum Delegate: Equatable {
            case dismissed
        }
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .methodSelected(.walk):
                state.route = .walk
                return .run { _ in
                    PostHogSDK.shared.capture("court_measure_walk_selected")
                }

            case .methodSelected(.manual):
                return .none

            case .backToHub:
                state.route = .hub
                return .none

            case .dismissTapped:
                return .send(.delegate(.dismissed))

            case .delegate:
                return .none
            }
        }
    }
}
