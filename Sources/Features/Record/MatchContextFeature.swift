import ComposableArchitecture
import Foundation

/// Post-match context form that appears after finishing a session and is editable from the detail.
@Reducer
struct MatchContextFeature {
    @ObservableState
    struct State: Equatable, Identifiable {
        let sessionId: String
        var accessToken: String

        var matchType: String = ""
        var surface: String = ""
        var position: String = ""
        var feeling: Int = 3
        var matchTag: String = ""
        var pitchId: String?
        // Structured post-match result
        var opponent: String = ""
        var outcome: String = ""
        var teamGoals: Int = 0
        var opponentGoals: Int = 0
        var competition: String = ""
        var goals: Int = 0
        var assists: Int = 0
        var notes: String = ""
        var pitches: [Pitch] = []
        var pitchesLoading = false
        var isSaving = false
        var errorMessage: String?
        var savedSuccessfully = false

        var id: String { sessionId }

        var canSave: Bool {
            !isSaving
        }

        init(sessionId: String, accessToken: String) {
            self.sessionId = sessionId
            self.accessToken = accessToken
        }

        /// Preloads the form from an existing session (edit from detail).
        init(session: SportSession, accessToken: String) {
            self.sessionId = session.id
            self.accessToken = accessToken
            self.matchType = session.matchType ?? ""
            self.surface = session.surface ?? ""
            self.position = session.position ?? ""
            self.feeling = session.feeling ?? 3
            self.matchTag = session.matchTag ?? ""
            self.pitchId = session.pitchId
            self.opponent = session.opponent ?? ""
            self.outcome = session.outcome ?? ""
            let parsed = MatchScore.parse(session.score)
            self.teamGoals = parsed.team
            self.opponentGoals = parsed.opponent
            self.competition = session.competition ?? ""
            self.goals = session.goals ?? 0
            self.assists = session.assists ?? 0
            self.notes = session.notes ?? session.result ?? ""
        }
    }

    enum Action: Equatable {
        case setMatchType(String)
        case setSurface(String)
        case setPosition(String)
        case setFeeling(Int)
        case setMatchTag(String)
        case setPitchId(String?)
        case setOpponent(String)
        case setOutcome(String)
        case setTeamGoals(Int)
        case setOpponentGoals(Int)
        case setCompetition(String)
        case setGoals(Int)
        case setAssists(Int)
        case setNotes(String)
        case loadPitches
        case pitchesResponse([Pitch])
        case saveTapped
        case saveResponse(Result<SportSession, APIError>)
        case dismissTapped
        case delegate(Delegate)

        enum Delegate: Equatable {
            case dismissed
        }
    }

    @Dependency(\.apiClient) var apiClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .setMatchType(v):
                state.matchType = v
                return .none
            case let .setSurface(v):
                state.surface = v
                return .none
            case let .setPosition(v):
                state.position = v
                return .none
            case let .setFeeling(v):
                state.feeling = v
                return .none
            case let .setMatchTag(v):
                state.matchTag = v
                return .none
            case let .setPitchId(v):
                state.pitchId = v
                return .none
            case let .setOpponent(v):
                state.opponent = v
                return .none
            case let .setOutcome(v):
                state.outcome = v
                return .none
            case let .setTeamGoals(v):
                state.teamGoals = min(max(0, v), MatchScore.maxGoals)
                return .none
            case let .setOpponentGoals(v):
                state.opponentGoals = min(max(0, v), MatchScore.maxGoals)
                return .none
            case let .setCompetition(v):
                state.competition = v
                return .none
            case let .setGoals(v):
                state.goals = max(0, v)
                return .none
            case let .setAssists(v):
                state.assists = max(0, v)
                return .none
            case let .setNotes(v):
                state.notes = v
                return .none

            case .loadPitches:
                state.pitchesLoading = true
                let token = state.accessToken
                return .run { send in
                    let result = try? await apiClient.listPitches(token)
                    await send(.pitchesResponse(result ?? []))
                }

            case let .pitchesResponse(pitches):
                state.pitches = pitches
                state.pitchesLoading = false
                return .none

            case .saveTapped:
                guard state.canSave else { return .none }
                state.isSaving = true
                state.errorMessage = nil
                let feeling = state.feeling
                let hasResult = !state.outcome.isEmpty
                let update = SessionContextUpdate(
                    matchType: state.matchType.isEmpty ? nil : state.matchType,
                    surface: state.surface.isEmpty ? nil : state.surface,
                    position: state.position.isEmpty ? nil : state.position,
                    result: nil,
                    feeling: feeling,
                    matchTag: state.matchTag.isEmpty ? nil : state.matchTag,
                    pitchId: state.pitchId,
                    opponent: state.opponent.isEmpty ? nil : state.opponent,
                    outcome: state.outcome.isEmpty ? nil : state.outcome,
                    score: MatchScore.format(team: state.teamGoals, opponent: state.opponentGoals, hasOutcome: !state.outcome.isEmpty),
                    competition: state.competition.isEmpty ? nil : state.competition,
                    goals: hasResult ? state.goals : nil,
                    assists: hasResult ? state.assists : nil,
                    notes: state.notes.isEmpty ? nil : state.notes
                )
                let token = state.accessToken
                let id = state.sessionId
                return .run { send in
                    await send(.saveResponse(Result {
                        try await apiClient.patchSessionContext(token, id, update)
                    }.mapError { $0 as? APIError ?? .invalidResponse }))
                }

            case .saveResponse(.success):
                state.isSaving = false
                state.savedSuccessfully = true
                MatchNotifications.shared.cancelResultReminder(sessionId: state.sessionId)
                return .send(.delegate(.dismissed))

            case .saveResponse(.failure):
                state.isSaving = false
                state.errorMessage = "Could not save match context."
                return .none

            case .dismissTapped:
                return .send(.delegate(.dismissed))

            case .delegate:
                return .none
            }
        }
    }
}

/// Parses and formats `team-opponent` score strings for the match result form.
enum MatchScore {
    static let maxGoals = 20

    static func parse(_ raw: String?) -> (team: Int, opponent: Int) {
        guard let raw else { return (0, 0) }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return (0, 0) }

        let separators = CharacterSet(charactersIn: "-–—:")
        let parts = trimmed
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard parts.count >= 2,
              let team = Int(parts[0]),
              let opponent = Int(parts[1])
        else {
            return (0, 0)
        }

        return (min(max(0, team), maxGoals), min(max(0, opponent), maxGoals))
    }

    static func format(team: Int, opponent: Int, hasOutcome: Bool) -> String? {
        guard hasOutcome else { return nil }
        return "\(team)-\(opponent)"
    }
}
