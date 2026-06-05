import ComposableArchitecture
import Foundation
import PostHog

@Reducer
struct InsightsFeature {
    @ObservableState
    struct State: Equatable {
        var accessToken: String
        var insights: SessionInsights?
        var recentSessions: [SportSession] = []
        var fatigueSessions: [SportSession] = []
        var speedRecordSessionId: String?
        var isLoading = false
        var isLoadingFatigue = false
        var errorMessage: String?
        @Presents var positionInsights: PositionInsightsFeature.State?
    }

    enum Action: Equatable {
        case onAppear
        case loadResponse(Result<SessionInsights, APIError>)
        case sessionsResponse(Result<[SportSession], APIError>)
        case recordsResponse(Result<PersonalRecords, APIError>)
        case fatigueLoaded([SportSession])
        case positionInsightsTapped
        case positionInsights(PresentationAction<PositionInsightsFeature.Action>)
    }

    @Dependency(\.apiClient) var apiClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                let token = state.accessToken
                return .merge(
                    .run { send in
                        await send(.loadResponse(Result {
                            try await apiClient.fetchInsights(token)
                        }.mapError { $0 as? APIError ?? .invalidResponse }))
                    },
                    .run { send in
                        await send(.sessionsResponse(Result {
                            try await apiClient.listSessions(token)
                        }.mapError { $0 as? APIError ?? .invalidResponse }))
                    },
                    .run { send in
                        await send(.recordsResponse(Result {
                            try await apiClient.fetchRecords(token)
                        }.mapError { $0 as? APIError ?? .invalidResponse }))
                    }
                )

            case let .loadResponse(.success(ins)):
                state.isLoading = false
                state.insights = ins
                return .none

            case .loadResponse(.failure):
                state.isLoading = false
                state.errorMessage = "Could not load insights."
                return .none

            case let .sessionsResponse(.success(sessions)):
                state.recentSessions = sessions.sorted { $0.startedAt > $1.startedAt }
                state.isLoadingFatigue = true
                let token = state.accessToken
                let ids = InsightsAnalytics.structuredSessionIds(from: sessions)
                return .run { send in
                    var loaded: [SportSession] = []
                    for id in ids {
                        if let detail = try? await apiClient.getSession(token, id),
                           detail.fatigueDrop != nil {
                            loaded.append(detail)
                        }
                    }
                    await send(.fatigueLoaded(loaded))
                }

            case .sessionsResponse(.failure):
                return .none

            case let .recordsResponse(.success(records)):
                state.speedRecordSessionId = records.records
                    .first { $0.metric == "speed_max_kmh" }?
                    .sessionId
                return .none

            case .recordsResponse(.failure):
                return .none

            case let .fatigueLoaded(sessions):
                state.isLoadingFatigue = false
                state.fatigueSessions = sessions
                return .none

            case .positionInsightsTapped:
                state.positionInsights = PositionInsightsFeature.State(accessToken: state.accessToken)
                return .run { _ in
                    PostHogSDK.shared.capture("insights_position_viewed")
                }

            case .positionInsights(.presented(.delegate(.dismissed))):
                state.positionInsights = nil
                return .none

            case .positionInsights:
                return .none
            }
        }
        .ifLet(\.$positionInsights, action: \.positionInsights) {
            PositionInsightsFeature()
        }
    }
}
