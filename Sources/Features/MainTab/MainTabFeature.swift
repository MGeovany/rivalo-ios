import ComposableArchitecture
import PostHog

/// Signed-in tab bar: Home, Record, You, Activities, and Insights.
@Reducer
struct MainTabFeature {
    @ObservableState
    struct State: Equatable {
        var accessToken: String
        var sessions: SessionsFeature.State
        var record = RecordFeature.State()
        var profile: ProfileFeature.State
        var insights: InsightsFeature.State
        var selectedTab: Tab = .home

        enum Tab: Equatable {
            case home
            case record
            case you
            case activities
            case insights
        }

        init(accessToken: String) {
            self.accessToken = accessToken
            self.sessions = SessionsFeature.State(accessToken: accessToken)
            self.profile = ProfileFeature.State(accessToken: accessToken)
            self.insights = InsightsFeature.State(accessToken: accessToken)
        }
    }

    enum Action {
        case task
        case watchSessionsChanged
        case watchSessionUploaded(SportSession)
        case openSessionFromNotification(MatchOpenEvent)
        case sessions(SessionsFeature.Action)
        case record(RecordFeature.Action)
        case profile(ProfileFeature.Action)
        case insights(InsightsFeature.Action)
        case selectedTabChanged(State.Tab)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case signOut
            case accountDeleted
        }
    }

    @Dependency(\.apiClient) var apiClient
    @Dependency(\.watchSyncClient) var watchSyncClient
    @Dependency(\.pendingSessions) var pendingSessions

    var body: some ReducerOf<Self> {
        Scope(state: \.sessions, action: \.sessions) {
            SessionsFeature()
        }
        Scope(state: \.record, action: \.record) {
            RecordFeature()
        }
        Scope(state: \.profile, action: \.profile) {
            ProfileFeature()
        }
        Scope(state: \.insights, action: \.insights) {
            InsightsFeature()
        }

        Reduce { state, action in
            switch action {
            case .task:
                let token = state.accessToken
                let api = apiClient
                let queue = pendingSessions
                let watch = watchSyncClient
                return .run { send in
                    await PitchesSync.refresh(accessToken: token, apiClient: api)

                    let pending = queue.all()
                    if !pending.isEmpty {
                        PostHogAnalytics.captureLog(
                            "draining \(pending.count) pending watch session(s) on launch",
                            level: .info
                        )
                    }
                    for item in pending {
                        do {
                            let created = try await WatchSessionUpload.createFromWatch(
                                accessToken: token,
                                payload: item.payload,
                                apiClient: api
                            )
                            queue.remove(item.id)
                            PostHogAnalytics.captureLog(
                                "pending watch session uploaded",
                                level: .info,
                                attributes: ["session_id": created.id, "queue_id": item.id.uuidString]
                            )
                            await send(.watchSessionUploaded(created))
                        } catch APIError.statusCode(let code) where (400..<500).contains(code) && code != 401 {
                            // Permanent rejection — drop it, never retry.
                            queue.remove(item.id)
                            PostHogAnalytics.captureLog(
                                "pending watch session rejected by server (4xx) — dropped from queue",
                                level: .error,
                                attributes: ["status_code": code, "queue_id": item.id.uuidString]
                            )
                            PostHogAnalytics.matchSaveFromWatchFailed(error: "status_\(code)")
                        } catch {
                            PostHogAnalytics.captureLog(
                                "pending watch session upload failed — will retry",
                                level: .error,
                                attributes: ["error": error.localizedDescription, "queue_id": item.id.uuidString]
                            )
                            PostHogAnalytics.matchSaveFromWatchFailed(error: error.localizedDescription)
                        }
                    }
                    await withDiscardingTaskGroup { group in
                        group.addTask {
                            for await received in watch.incomingSessions() {
                                // Skip duplicates already in the queue (WCSession re-delivers on
                                // every launch until the session uploads successfully).
                                let isDuplicate = queue.all().contains {
                                    $0.payload.startedAt == received.startedAt
                                }
                                guard !isDuplicate else {
                                    PostHogAnalytics.captureLog(
                                        "watch session skipped — duplicate already queued",
                                        level: .info,
                                        attributes: ["started_at": received.startedAt.timeIntervalSince1970]
                                    )
                                    continue
                                }
                                PostHogAnalytics.captureLog(
                                    "watch session received via WatchConnectivity",
                                    level: .info,
                                    attributes: [
                                        "duration_s": received.durationS,
                                        "distance_m": received.distanceM,
                                        "source": received.source,
                                        "mode": received.mode,
                                    ]
                                )
                                let queued = queue.enqueue(received)
                                do {
                                    let created = try await WatchSessionUpload.createFromWatch(
                                        accessToken: token,
                                        payload: received,
                                        apiClient: api
                                    )
                                    queue.remove(queued.id)
                                    PostHogAnalytics.captureLog(
                                        "watch session uploaded successfully",
                                        level: .info,
                                        attributes: ["session_id": created.id]
                                    )
                                    await send(.watchSessionUploaded(created))
                                } catch APIError.statusCode(let code) where (400..<500).contains(code) && code != 401 {
                                    // Permanent client-side rejection — remove from queue so it is
                                    // never retried. Log it so we can see the payload is invalid.
                                    queue.remove(queued.id)
                                    PostHogAnalytics.captureLog(
                                        "watch session rejected by server (4xx) — dropped from queue",
                                        level: .error,
                                        attributes: [
                                            "status_code": code,
                                            "queue_id": queued.id.uuidString,
                                        ]
                                    )
                                    PostHogAnalytics.matchSaveFromWatchFailed(error: "status_\(code)")
                                } catch {
                                    PostHogAnalytics.captureLog(
                                        "watch session upload failed — will retry",
                                        level: .error,
                                        attributes: [
                                            "error": error.localizedDescription,
                                            "queue_id": queued.id.uuidString,
                                        ]
                                    )
                                    PostHogAnalytics.matchSaveFromWatchFailed(error: error.localizedDescription)
                                }
                            }
                        }
                        // Retries sessions that failed to upload (e.g. API was unreachable).
                        group.addTask {
                            while !Task.isCancelled {
                                try? await Task.sleep(for: .seconds(30))
                                for item in queue.all() {
                                    do {
                                        let created = try await WatchSessionUpload.createFromWatch(
                                            accessToken: token,
                                            payload: item.payload,
                                            apiClient: api
                                        )
                                        queue.remove(item.id)
                                        PostHogAnalytics.captureLog(
                                            "pending watch session uploaded via retry",
                                            level: .info,
                                            attributes: ["session_id": created.id, "queue_id": item.id.uuidString]
                                        )
                                        await send(.watchSessionUploaded(created))
                                    } catch APIError.statusCode(let code) where (400..<500).contains(code) && code != 401 {
                                        // Permanent client-side rejection — drop from queue.
                                        queue.remove(item.id)
                                        PostHogAnalytics.captureLog(
                                            "queued watch session rejected by server (4xx) — dropped",
                                            level: .error,
                                            attributes: ["status_code": code, "queue_id": item.id.uuidString]
                                        )
                                    } catch {
                                        // Network error or 5xx — keep in queue for next retry.
                                        PostHogAnalytics.captureLog(
                                            "queued watch session retry failed — will try again",
                                            level: .error,
                                            attributes: ["error": error.localizedDescription, "queue_id": item.id.uuidString]
                                        )
                                    }
                                }
                            }
                        }
                        group.addTask {
                            for await event in watch.liveMatchEvents() {
                                await send(.record(.liveEventReceived(event)))
                            }
                        }
                        group.addTask {
                            for await open in MatchNotifications.shared.events() {
                                await send(.openSessionFromNotification(open))
                            }
                        }
                    }
                }

            case .watchSessionsChanged:
                return .send(.sessions(.onAppear))

            case let .watchSessionUploaded(created):
                state.selectedTab = .home
                let summaryBody = "\(created.distanceKmText) · \(created.durationText)"
                    + (created.matchRating.map { String(format: " · rating %.0f", $0) } ?? "")
                return .merge(
                    .send(.sessions(.onAppear)),
                    .send(.sessions(.openSession(created.id, true))),
                    // Dismiss the live match view if it is still showing (Watch ended the match).
                    .send(.record(.dismissLiveMatch)),
                    .run { _ in
                        PostHogAnalytics.matchSavedFromWatch(
                            durationS: created.durationS,
                            distanceM: created.distanceM,
                            rating: created.matchRating
                        )
                        MatchNotifications.shared.scheduleSummary(
                            sessionId: created.id,
                            title: "Match saved ⚽️",
                            body: summaryBody
                        )
                        MatchNotifications.shared.scheduleResultReminder(sessionId: created.id)
                    }
                )

            case let .openSessionFromNotification(open):
                state.selectedTab = .home
                return .merge(
                    .send(.sessions(.onAppear)),
                    .send(.sessions(.openSession(open.sessionId, open.openResult)))
                )

            case .profile(.delegate(.signOut)):
                return .send(.delegate(.signOut))

            case .profile(.delegate(.accountDeleted)):
                return .send(.delegate(.accountDeleted))

            case let .selectedTabChanged(tab):
                state.selectedTab = tab
                switch tab {
                case .home:
                    return .send(.sessions(.onAppear))
                case .you:
                    return .send(.profile(.onAppear))
                case .insights:
                    return .send(.insights(.onAppear))
                case .activities:
                    return .send(.sessions(.onAppear))
                case .record:
                    return .none
                }

            case .sessions, .record, .profile, .insights, .delegate:
                return .none
            }
        }
    }
}
