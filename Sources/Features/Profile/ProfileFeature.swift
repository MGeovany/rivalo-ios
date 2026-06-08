import ComposableArchitecture
import Foundation
import PostHog

/// Loads and edits the authenticated user's profile via the backend.
@Reducer
struct ProfileFeature {
    @ObservableState
    struct State: Equatable {
        var accessToken: String
        var profile: Profile?
        var isLoading = false
        var isSaving = false
        var errorMessage: String?

        // Editable fields, mirrored from the loaded profile.
        var displayName = ""
        var preferredPosition = ""
        var heightText = ""
        var weightText = ""
        var birthDate: Date?
        var heightUnit: HeightUnit = .loadPreferred()
        var weightUnit: WeightUnit = .loadPreferred()
        /// ISO country code stored locally per user (profile UI).
        var countryCode: String = ProfileCountryStore.defaultCode()
        var sessions: [SportSession] = []
        var isDeleteAccountAlertShown = false
        var isDeletingAccount = false
        @Presents var courts: CourtsFeature.State?
        @Presents var badges: BadgesFeature.State?
        @Presents var rivalries: RivalriesFeature.State?
        @Presents var goals: GoalsFeature.State?
        @Presents var serverStatus: ServerStatusFeature.State?

        var canSave: Bool {
            !displayName.trimmingCharacters(in: .whitespaces).isEmpty && !isSaving
        }

        /// Snapshot for the shareable player progress card.
        var playerCard: PlayerCardModel? {
            guard let profile else { return nil }
            let name = profile.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }

            let metrics = PlayerCardStatsBuilder.build(from: sessions)
            return PlayerCardModel(
                displayName: name,
                position: profile.preferredPosition,
                positionAbbrev: ProfileFormatting.positionAbbreviation(profile.preferredPosition),
                matchCount: metrics.matchCount,
                rank: metrics.rank,
                tierProgress: metrics.tierProgress,
                physicalRating: metrics.physicalRating,
                displayStats: metrics.displayStats,
                countryCode: countryCode,
                initials: ProfileFormatting.initials(from: name)
            )
        }

    }

    enum Action: BindableAction, Equatable {
        case onAppear
        case binding(BindingAction<State>)
        case loadResponse(Result<Profile, APIError>)
        case sessionsForCardResponse(Result<[SportSession], APIError>)
        case saveTapped
        case saveResponse(Result<Profile, APIError>)
        case signOutTapped
        case deleteAccountTapped
        case deleteAccountCancelled
        case deleteAccountConfirmed
        case deleteAccountSucceeded
        case deleteAccountFailed
        case heightUnitChanged(HeightUnit)
        case weightUnitChanged(WeightUnit)
        case countryCodeChanged(String)
        case errorDismissed
        case courtsTapped
        case courts(PresentationAction<CourtsFeature.Action>)
        case badgesTapped
        case badges(PresentationAction<BadgesFeature.Action>)
        case rivalriesTapped
        case rivalries(PresentationAction<RivalriesFeature.Action>)
        case goalsTapped
        case goals(PresentationAction<GoalsFeature.Action>)
        case devTapped
        case serverStatus(PresentationAction<ServerStatusFeature.Action>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case signOut
            case accountDeleted
        }
    }

    @Dependency(\.apiClient) var apiClient

    private enum CancelID { case errorToast }

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = state.profile == nil
                state.errorMessage = nil
                let token = state.accessToken
                return .run { send in
                    async let profile = Result { try await apiClient.me(token) }
                        .mapError { $0 as? APIError ?? .invalidResponse }
                    async let sessions = Result { try await apiClient.listSessions(token) }
                        .mapError { $0 as? APIError ?? .invalidResponse }
                    await send(.loadResponse(await profile))
                    await send(.sessionsForCardResponse(await sessions))
                }

            case let .loadResponse(.success(profile)):
                state.isLoading = false
                state.apply(profile)
                return .none

            case .loadResponse(.failure):
                state.isLoading = false
                state.errorMessage = "Could not load your profile."
                return Self.scheduleErrorDismiss()

            case let .sessionsForCardResponse(.success(sessions)):
                state.sessions = sessions
                return .none

            case .sessionsForCardResponse(.failure):
                return .none

            case .saveTapped:
                guard state.canSave else { return .none }
                state.isSaving = true
                state.errorMessage = nil
                let token = state.accessToken
                let update = state.makeUpdate()
                return .run { send in
                    await send(.saveResponse(Result { try await apiClient.updateMe(token, update) }
                        .mapError { $0 as? APIError ?? .invalidResponse }))
                }

            case let .saveResponse(.success(profile)):
                state.isSaving = false
                state.apply(profile)
                let token = state.accessToken
                return .merge(
                    .run { _ in PostHogSDK.shared.capture("profile_saved") },
                    .run { send in
                        await send(.sessionsForCardResponse(Result {
                            try await apiClient.listSessions(token)
                        }.mapError { $0 as? APIError ?? .invalidResponse }))
                    }
                )

            case .saveResponse(.failure):
                state.isSaving = false
                state.errorMessage = "Could not save your profile."
                return Self.scheduleErrorDismiss()

            case .signOutTapped:
                return .send(.delegate(.signOut))

            case .deleteAccountTapped:
                state.isDeleteAccountAlertShown = true
                return .none

            case .deleteAccountCancelled:
                state.isDeleteAccountAlertShown = false
                return .none

            case .deleteAccountConfirmed:
                state.isDeleteAccountAlertShown = false
                state.isDeletingAccount = true
                state.errorMessage = nil
                let token = state.accessToken
                return .run { send in
                    do {
                        try await apiClient.deleteAccount(token)
                        await send(.deleteAccountSucceeded)
                    } catch {
                        await send(.deleteAccountFailed)
                    }
                }

            case .deleteAccountSucceeded:
                state.isDeletingAccount = false
                return .merge(
                    .run { _ in PostHogSDK.shared.capture("account_deleted") },
                    .send(.delegate(.accountDeleted))
                )

            case .deleteAccountFailed:
                state.isDeletingAccount = false
                state.errorMessage = "Could not delete your account. Please try again."
                return Self.scheduleErrorDismiss()

            case let .heightUnitChanged(unit):
                let cm = state.heightUnit.parseToCm(state.heightText)
                state.heightUnit = unit
                unit.savePreferred()
                state.heightText = unit.format(cm: cm)
                return .none

            case let .weightUnitChanged(unit):
                let kg = state.weightUnit.parseToKg(state.weightText)
                state.weightUnit = unit
                unit.savePreferred()
                state.weightText = unit.format(kg: kg)
                return .none

            case let .countryCodeChanged(code):
                let normalized = code.uppercased()
                state.countryCode = normalized
                if let userId = state.profile?.id {
                    ProfileCountryStore.save(userId: userId, code: normalized)
                }
                return .none

            case .errorDismissed:
                state.errorMessage = nil
                return .cancel(id: CancelID.errorToast)

            case .courtsTapped:
                state.courts = CourtsFeature.State(accessToken: state.accessToken)
                return .none

            case .courts(.presented(.delegate(.dismissed))):
                state.courts = nil
                return .none

            case .courts:
                return .none

            case .badgesTapped:
                state.badges = BadgesFeature.State(accessToken: state.accessToken)
                return .none

            case .badges(.presented(.delegate(.dismissed))):
                state.badges = nil
                return .none

            case .badges:
                return .none

            case .rivalriesTapped:
                state.rivalries = RivalriesFeature.State(accessToken: state.accessToken)
                return .none

            case .rivalries(.presented(.delegate(.dismissed))):
                state.rivalries = nil
                return .none

            case .rivalries:
                return .none

            case .goalsTapped:
                state.goals = GoalsFeature.State(accessToken: state.accessToken)
                return .none

            case .goals(.presented(.delegate(.dismissed))):
                state.goals = nil
                return .none

            case .goals:
                return .none

            case .devTapped:
                state.serverStatus = ServerStatusFeature.State()
                return .none

            case .serverStatus:
                return .none

            case .binding, .delegate:
                return .none
            }
        }
        .ifLet(\.$courts, action: \.courts) {
            CourtsFeature()
        }
        .ifLet(\.$badges, action: \.badges) {
            BadgesFeature()
        }
        .ifLet(\.$rivalries, action: \.rivalries) {
            RivalriesFeature()
        }
        .ifLet(\.$goals, action: \.goals) {
            GoalsFeature()
        }
        .ifLet(\.$serverStatus, action: \.serverStatus) {
            ServerStatusFeature()
        }
    }
}

private extension ProfileFeature {
    static func scheduleErrorDismiss() -> Effect<Action> {
        .run { send in
            try await Task.sleep(for: .seconds(4))
            await send(.errorDismissed)
        }
        .cancellable(id: CancelID.errorToast, cancelInFlight: true)
    }
}

private extension ProfileFeature.State {
    /// Mirrors a loaded profile into the editable fields.
    mutating func apply(_ profile: Profile) {
        self.profile = profile
        displayName = profile.displayName
        preferredPosition = profile.preferredPosition ?? ""
        heightText = heightUnit.format(cm: profile.heightCm)
        weightText = weightUnit.format(kg: profile.weightKg)
        // Prefer the full stored date; fall back to year-only for old profiles.
        birthDate = ProfileBirthDate.date(fromISO: profile.birthDate)
            ?? profile.birthYear.map { ProfileBirthDate.date(fromBirthYear: $0) }
        countryCode = ProfileCountryStore.load(userId: profile.id) ?? ProfileCountryStore.defaultCode()
    }

    /// Builds the update payload from the editable fields.
    func makeUpdate() -> ProfileUpdate {
        let position = preferredPosition.trimmingCharacters(in: .whitespaces)
        return ProfileUpdate(
            displayName: displayName.trimmingCharacters(in: .whitespaces),
            preferredPosition: position.isEmpty ? nil : position,
            heightCm: heightUnit.parseToCm(heightText),
            weightKg: weightUnit.parseToKg(weightText),
            birthYear: ProfileBirthDate.birthYear(from: birthDate),
            birthDate: ProfileBirthDate.isoString(from: birthDate)
        )
    }

}

/// Read-only data for the shareable player progress card.
struct PlayerCardModel: Equatable {
    let displayName: String
    let position: String?
    let positionAbbrev: String
    let matchCount: Int
    let rank: PlayerCardRank
    let tierProgress: Int
    let physicalRating: Int?
    let displayStats: PlayerCardDisplayStats
    let countryCode: String
    let initials: String
}
