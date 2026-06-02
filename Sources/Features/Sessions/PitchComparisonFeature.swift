import ComposableArchitecture
import Foundation

/// Compares all sessions played at the same pitch. Loads the user's
/// sessions, filters them by `pitchId`, and exposes per-session rows plus
/// aggregate bests/averages for the venue.
@Reducer
struct PitchComparisonFeature {
    @ObservableState
    struct State: Equatable, Identifiable {
        var accessToken: String
        let pitchId: String
        var pitchName: String
        /// Highlighted in the list (the session the user came from).
        var focusedSessionId: String?
        var sessions: [SportSession] = []
        var isLoading = false
        var errorMessage: String?

        var id: String { pitchId }

        /// Sessions at this pitch, most recent first.
        var samePitchSessions: [SportSession] {
            sessions
                .filter { $0.pitchId == pitchId }
                .sorted { $0.startedAt > $1.startedAt }
        }

        var stats: PitchComparisonStats? {
            PitchComparisonStats.build(from: samePitchSessions)
        }
    }

    enum Action: Equatable {
        case onAppear
        case listResponse(Result<[SportSession], APIError>)
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
            case .onAppear:
                state.isLoading = state.sessions.isEmpty
                state.errorMessage = nil
                let token = state.accessToken
                return .run { send in
                    await send(.listResponse(Result { try await apiClient.listSessions(token) }
                        .mapError { $0 as? APIError ?? .invalidResponse }))
                }

            case let .listResponse(.success(sessions)):
                state.isLoading = false
                state.sessions = sessions
                return .none

            case .listResponse(.failure):
                state.isLoading = false
                state.errorMessage = "Could not load sessions for this court."
                return .none

            case .dismissTapped:
                return .send(.delegate(.dismissed))

            case .delegate:
                return .none
            }
        }
    }
}

/// Aggregate bests/averages across the sessions played at one pitch.
struct PitchComparisonStats: Equatable {
    var count: Int
    var avgDistanceM: Double
    var bestDistanceM: Double
    var avgRating: Double?
    var bestRating: Double?
    var avgDurationS: Double
    var bestSessionId: String?

    /// Builds stats from the sessions at a single pitch. Returns nil when empty.
    static func build(from sessions: [SportSession]) -> PitchComparisonStats? {
        guard !sessions.isEmpty else { return nil }
        let count = sessions.count

        let avgDistance = sessions.reduce(0.0) { $0 + $1.distanceM } / Double(count)
        let bestDistance = sessions.map(\.distanceM).max() ?? 0
        let avgDuration = sessions.reduce(0.0) { $0 + Double($1.durationS) } / Double(count)

        let ratings = sessions.compactMap(\.matchRating)
        let avgRating = ratings.isEmpty ? nil : ratings.reduce(0, +) / Double(ratings.count)
        let bestRating = ratings.max()

        // "Best" session = highest match rating, else longest distance.
        let bestSession = sessions.max { lhs, rhs in
            switch (lhs.matchRating, rhs.matchRating) {
            case let (l?, r?): return l < r
            case (nil, _?): return true
            case (_?, nil): return false
            case (nil, nil): return lhs.distanceM < rhs.distanceM
            }
        }

        return PitchComparisonStats(
            count: count,
            avgDistanceM: avgDistance,
            bestDistanceM: bestDistance,
            avgRating: avgRating,
            bestRating: bestRating,
            avgDurationS: avgDuration,
            bestSessionId: bestSession?.id
        )
    }
}
