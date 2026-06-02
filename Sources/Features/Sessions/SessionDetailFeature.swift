import ComposableArchitecture
import Foundation

/// Loads and displays a single session with Strava-style charts and actions.
@Reducer
struct SessionDetailFeature {
    @ObservableState
    struct State: Equatable, Identifiable {
        var accessToken: String
        let sessionId: String
        var session: SportSession?
        var meta: SessionMeta = SessionMeta()
        var photos: [Data] = []
        var isLoading = false
        var isDeleting = false
        var errorMessage: String?
        var showVenuePrompt = false
        var venueDraft = ""
        var showDeleteConfirm = false
        /// User's own averages, for the session-vs-average comparison (G.4).
        var averages: StatsAverages?
        /// When true, opens the result form automatically on appear (deep-link from notification).
        var autoOpenResult = false
        @Presents var comparison: PitchComparisonFeature.State?
        @Presents var matchContext: MatchContextFeature.State?

        var id: String { sessionId }

        init(accessToken: String, id: String, session: SportSession? = nil, autoOpenResult: Bool = false) {
            self.accessToken = accessToken
            self.sessionId = id
            self.session = session
            self.autoOpenResult = autoOpenResult
            if let session {
                self.meta = SessionMetaStore.load(sessionId: session.id)
                self.photos = SessionPhotoStore.load(sessionId: session.id)
            }
        }
    }

    enum Action: Equatable {
        case onAppear
        case loadResponse(Result<SportSession, APIError>)
        case averagesResponse(Result<SessionInsights, APIError>)
        case dismissTapped
        case shareTapped
        case editTapped
        case saveVenueTapped
        case venueDraftChanged(String)
        case confirmVenueTapped
        case cancelVenueTapped
        case deleteTapped
        case confirmDeleteTapped
        case cancelDeleteTapped
        case deleteSucceeded
        case deleteFailed
        case photosChanged
        case comparePitchTapped
        case comparison(PresentationAction<PitchComparisonFeature.Action>)
        case addResultTapped
        case matchContext(PresentationAction<MatchContextFeature.Action>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case dismissed
            case deleted
            case requestEdit(SportSession)
            case updated(SportSession)
        }
    }

    @Dependency(\.apiClient) var apiClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.meta = SessionMetaStore.load(sessionId: state.sessionId)
                state.photos = SessionPhotoStore.load(sessionId: state.sessionId)
                let token = state.accessToken
                let averagesEffect: Effect<Action> = state.averages == nil
                    ? .run { send in
                        await send(.averagesResponse(Result { try await apiClient.fetchInsights(token) }
                            .mapError { $0 as? APIError ?? .invalidResponse }))
                    }
                    : .none
                let autoResultEffect: Effect<Action> =
                    state.autoOpenResult && state.session != nil ? .send(.addResultTapped) : .none
                if let samples = state.session?.samples, !samples.isEmpty {
                    return .merge(averagesEffect, autoResultEffect)
                }
                state.isLoading = true
                let id = state.sessionId
                return .merge(
                    averagesEffect,
                    autoResultEffect,
                    .run { send in
                        await send(.loadResponse(Result { try await apiClient.getSession(token, id) }
                            .mapError { $0 as? APIError ?? .invalidResponse }))
                    }
                )

            case let .averagesResponse(.success(insights)):
                state.averages = insights.averages
                return .none

            case .averagesResponse(.failure):
                return .none

            case let .loadResponse(.success(session)):
                state.isLoading = false
                state.session = session
                state.meta = SessionMetaStore.load(sessionId: session.id)
                state.photos = SessionPhotoStore.load(sessionId: session.id)
                if state.autoOpenResult && state.matchContext == nil {
                    return .send(.addResultTapped)
                }
                return .none

            case .loadResponse(.failure):
                state.isLoading = false
                state.errorMessage = "Could not load the session."
                return .none

            case .dismissTapped:
                return .send(.delegate(.dismissed))

            case .shareTapped:
                return .none

            case .editTapped:
                guard let session = state.session else { return .none }
                return .send(.delegate(.requestEdit(session)))

            case .saveVenueTapped:
                state.venueDraft = state.meta.venueName ?? ""
                state.showVenuePrompt = true
                return .none

            case let .venueDraftChanged(text):
                state.venueDraft = text
                return .none

            case .confirmVenueTapped:
                state.showVenuePrompt = false
                var meta = state.meta
                let name = state.venueDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                meta.venueName = name.isEmpty ? nil : name
                state.meta = meta
                SessionMetaStore.save(sessionId: state.sessionId, meta: meta)
                return .none

            case .cancelVenueTapped:
                state.showVenuePrompt = false
                return .none

            case .deleteTapped:
                state.showDeleteConfirm = true
                return .none

            case .cancelDeleteTapped:
                state.showDeleteConfirm = false
                return .none

            case .confirmDeleteTapped:
                state.showDeleteConfirm = false
                state.isDeleting = true
                let token = state.accessToken
                let id = state.sessionId
                return .run { send in
                    do {
                        try await apiClient.deleteSession(token, id)
                        await send(.deleteSucceeded)
                    } catch {
                        await send(.deleteFailed)
                    }
                }

            case .deleteSucceeded:
                state.isDeleting = false
                SessionMetaStore.delete(sessionId: state.sessionId)
                SessionPhotoStore.deleteAll(sessionId: state.sessionId)
                return .send(.delegate(.deleted))

            case .deleteFailed:
                state.isDeleting = false
                state.errorMessage = "Could not delete this activity."
                return .none

            case .photosChanged:
                state.photos = SessionPhotoStore.load(sessionId: state.sessionId)
                return .none

            case .comparePitchTapped:
                guard let pitchId = state.session?.pitchId else { return .none }
                let pitchName = PitchCacheStore.load().first { $0.id == pitchId }?.name ?? "This court"
                state.comparison = PitchComparisonFeature.State(
                    accessToken: state.accessToken,
                    pitchId: pitchId,
                    pitchName: pitchName,
                    focusedSessionId: state.sessionId
                )
                return .none

            case .comparison(.presented(.delegate(.dismissed))):
                state.comparison = nil
                return .none

            case .comparison:
                return .none

            case .addResultTapped:
                state.autoOpenResult = false
                guard let session = state.session else { return .none }
                state.matchContext = MatchContextFeature.State(session: session, accessToken: state.accessToken)
                return .none

            case .matchContext(.presented(.delegate(.dismissed))):
                state.matchContext = nil
                // Reload to reflect the saved result.
                let token = state.accessToken
                let id = state.sessionId
                return .run { send in
                    await send(.loadResponse(Result { try await apiClient.getSession(token, id) }
                        .mapError { $0 as? APIError ?? .invalidResponse }))
                }

            case .matchContext:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$comparison, action: \.comparison) {
            PitchComparisonFeature()
        }
        .ifLet(\.$matchContext, action: \.matchContext) {
            MatchContextFeature()
        }
    }
}
