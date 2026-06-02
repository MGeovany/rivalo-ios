import ComposableArchitecture
import Foundation

/// Temporary form to create a manual session, used to validate the sessions
/// backend end-to-end. Replaced by the watch capture flow in a later phase.
@Reducer
struct SessionEntryFeature {
    @ObservableState
    struct State: Equatable {
        let accessToken: String
        var durationMin = ""
        var distanceKm = ""
        var hrAvg = ""
        var hrMax = ""
        var sprints = ""
        var intensity = ""
        var isSubmitting = false
        var errorMessage: String?

        var canSubmit: Bool {
            (Int(durationMin) ?? 0) > 0 && !isSubmitting
        }
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case submitTapped
        case cancelTapped
        case submitResult(Result<SportSession, APIError>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case created(SportSession)
            case cancelled
        }
    }

    @Dependency(\.apiClient) var apiClient
    @Dependency(\.date) var date

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                state.errorMessage = nil
                return .none

            case .cancelTapped:
                return .send(.delegate(.cancelled))

            case .submitTapped:
                guard state.canSubmit else { return .none }
                state.isSubmitting = true
                state.errorMessage = nil

                let ended = date.now
                let durationS = (Int(state.durationMin) ?? 0) * 60
                let new = NewSportSession(
                    startedAt: ended.addingTimeInterval(TimeInterval(-durationS)),
                    endedAt: ended,
                    durationS: durationS,
                    distanceM: (Double(state.distanceKm) ?? 0) * 1000,
                    hrAvg: Int(state.hrAvg),
                    hrMax: Int(state.hrMax),
                    sprints: Int(state.sprints) ?? 0,
                    intensity: Double(state.intensity),
                    source: "manual"
                )
                let token = state.accessToken
                return .run { send in
                    await send(.submitResult(Result { try await apiClient.createSession(token, new) }
                        .mapError { $0 as? APIError ?? .invalidResponse }))
                }

            case let .submitResult(.success(created)):
                state.isSubmitting = false
                return .send(.delegate(.created(created)))

            case .submitResult(.failure):
                state.isSubmitting = false
                state.errorMessage = "Could not create the session. Please try again."
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
