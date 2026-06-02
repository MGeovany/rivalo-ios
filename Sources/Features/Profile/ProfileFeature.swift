import ComposableArchitecture
import Foundation

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
        var birthYearText = ""
        var heightUnit: HeightUnit = .loadPreferred()
        var weightUnit: WeightUnit = .loadPreferred()
        /// ISO country code stored locally per user (profile UI).
        var countryCode: String = ProfileCountryStore.defaultCode()
        var sessions: [SportSession] = []
        /// JPEG bytes for the player card photo (device-local until backend avatar exists).
        var avatarImageData: Data?

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
                physicalRating: metrics.physicalRating,
                topSpeedKmh: metrics.topSpeedKmh,
                avgSprints: metrics.avgSprints,
                avgDistanceKm: metrics.avgDistanceKm,
                fatigueDropPct: metrics.fatigueDropPct,
                badge: metrics.badge,
                initials: ProfileFormatting.initials(from: name),
                avatarImageData: avatarImageData
            )
        }

        var hasCardPhoto: Bool {
            avatarImageData != nil
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
        case heightUnitChanged(HeightUnit)
        case weightUnitChanged(WeightUnit)
        case photoSelected(Data)
        case photoRemoved
        case countryCodeChanged(String)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case signOut
        }
    }

    @Dependency(\.apiClient) var apiClient

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
                return .none

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
                return .run { send in
                    await send(.sessionsForCardResponse(Result {
                        try await apiClient.listSessions(token)
                    }.mapError { $0 as? APIError ?? .invalidResponse }))
                }

            case .saveResponse(.failure):
                state.isSaving = false
                state.errorMessage = "Could not save your profile."
                return .none

            case .signOutTapped:
                return .send(.delegate(.signOut))

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

            case let .photoSelected(data):
                guard let userId = state.profile?.id else { return .none }
                state.avatarImageData = ProfilePhotoStore.save(userId: userId, rawImageData: data)
                return .none

            case .photoRemoved:
                guard let userId = state.profile?.id else { return .none }
                ProfilePhotoStore.delete(userId: userId)
                state.avatarImageData = nil
                return .none

            case let .countryCodeChanged(code):
                let normalized = code.uppercased()
                state.countryCode = normalized
                if let userId = state.profile?.id {
                    ProfileCountryStore.save(userId: userId, code: normalized)
                }
                return .none

            case .binding, .delegate:
                return .none
            }
        }
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
        birthYearText = profile.birthYear.map { "\($0)" } ?? ""
        avatarImageData = ProfilePhotoStore.load(userId: profile.id)
        countryCode = ProfileCountryStore.load(userId: profile.id) ?? ProfileCountryStore.defaultCode()
    }

    /// Builds the update payload from the editable fields.
    func makeUpdate() -> ProfileUpdate {
        let position = preferredPosition.trimmingCharacters(in: .whitespaces)
        let birthYear = Int(birthYearText.trimmingCharacters(in: .whitespaces))
        return ProfileUpdate(
            displayName: displayName.trimmingCharacters(in: .whitespaces),
            preferredPosition: position.isEmpty ? nil : position,
            heightCm: heightUnit.parseToCm(heightText),
            weightKg: weightUnit.parseToKg(weightText),
            birthYear: birthYear
        )
    }

}

/// Read-only data for the shareable player progress card.
struct PlayerCardModel: Equatable {
    let displayName: String
    let position: String?
    let positionAbbrev: String
    let physicalRating: Int?
    let topSpeedKmh: Double?
    let avgSprints: Int?
    let avgDistanceKm: Double?
    let fatigueDropPct: Double?
    let badge: PlayerCardBadge?
    let initials: String
    let avatarImageData: Data?
}
