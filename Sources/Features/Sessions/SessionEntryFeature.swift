import ComposableArchitecture
import Foundation

/// Temporary form to create a manual session, used to validate the sessions
/// backend end-to-end. Replaced by the watch capture flow in a later phase.
@Reducer
struct SessionEntryFeature {
    @ObservableState
    struct State: Equatable {
        let accessToken: String
        var editingSessionId: String?
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

        var isEditing: Bool { editingSessionId != nil }

        init(accessToken: String, editing: SportSession? = nil) {
            self.accessToken = accessToken
            self.editingSessionId = editing?.id
            guard let editing else { return }
            durationMin = String(editing.durationS / 60)
            distanceKm = String(format: "%.2f", editing.distanceM / 1000)
            hrAvg = editing.hrAvg.map { "\($0)" } ?? ""
            hrMax = editing.hrMax.map { "\($0)" } ?? ""
            sprints = "\(editing.sprints)"
            intensity = editing.intensity.map { String(format: "%.0f", $0) } ?? ""
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
            case updated(SportSession)
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
                let started = ended.addingTimeInterval(TimeInterval(-durationS))
                let token = state.accessToken

                if let editId = state.editingSessionId {
                    let update = SportSessionUpdate(
                        startedAt: started,
                        endedAt: ended,
                        durationS: durationS,
                        distanceM: (Double(state.distanceKm) ?? 0) * 1000,
                        hrAvg: Int(state.hrAvg),
                        hrMax: Int(state.hrMax),
                        speedMaxKmh: nil,
                        sprints: Int(state.sprints) ?? 0,
                        intensity: Double(state.intensity),
                        caloriesKcal: nil
                    )
                    return .run { send in
                        await send(.submitResult(Result {
                            try await apiClient.updateSession(token, editId, update)
                        }.mapError { $0 as? APIError ?? .invalidResponse }))
                    }
                }

                let new = NewSportSession(
                    startedAt: started,
                    endedAt: ended,
                    durationS: durationS,
                    distanceM: (Double(state.distanceKm) ?? 0) * 1000,
                    hrAvg: Int(state.hrAvg),
                    hrMax: Int(state.hrMax),
                    sprints: Int(state.sprints) ?? 0,
                    intensity: Double(state.intensity),
                    source: "manual"
                )
                return .run { send in
                    await send(.submitResult(Result { try await apiClient.createSession(token, new) }
                        .mapError { $0 as? APIError ?? .invalidResponse }))
                }

            case let .submitResult(.success(saved)):
                state.isSubmitting = false
                if state.editingSessionId != nil {
                    return .send(.delegate(.updated(saved)))
                }
                return .send(.delegate(.created(saved)))

            case .submitResult(.failure):
                state.isSubmitting = false
                state.errorMessage = state.isEditing
                    ? "Could not update the session."
                    : "Could not create the session. Please try again."
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
