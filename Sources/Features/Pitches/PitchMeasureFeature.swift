import ComposableArchitecture
import Foundation

/// V2-F hub: pick walk or manual pitch measurement.
@Reducer
struct PitchMeasureFeature {
    @ObservableState
    struct State: Equatable {
        var accessToken: String
        var route: Route = .hub
        var alertMessage: String?

        enum Route: Equatable {
            case hub
            case walk
            case manual
        }

        init(accessToken: String, prefill: PitchMeasurementMethod? = nil) {
            self.accessToken = accessToken
            if let prefill {
                switch prefill {
                case .walk: route = .walk
                case .manual: route = .manual
                }
            }
        }

        mutating func open(_ method: PitchMeasurementMethod) {
            switch method {
            case .walk: route = .walk
            case .manual: route = .manual
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
            case let .methodSelected(method):
                state.open(method)
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
