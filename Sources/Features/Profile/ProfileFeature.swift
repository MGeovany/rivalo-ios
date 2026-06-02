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
        var birthDate: Date?
        var heightUnit: HeightUnit = .loadPreferred()
        var weightUnit: WeightUnit = .loadPreferred()
        /// ISO country code stored locally per user (profile UI).
        var countryCode: String = ProfileCountryStore.defaultCode()
        var sessions: [SportSession] = []
        /// PNG bytes for the player card cutout (device-local until backend avatar exists).
        var avatarImageData: Data?
        /// Raw photo chosen from the library, awaiting placement + background removal.
        var pendingPhotoData: Data?
        var photoPlacement: PlayerCardPhotoPlacement = .default
        /// When true, the card photo cannot be dragged or pinched (after save).
        var isPhotoPlacementLocked = false
        var isProcessingPhoto = false
        /// Saved or pending photo still has a full background and needs Vision cutout.
        var photoNeedsBackgroundRemoval = false
        @Presents var courts: CourtsFeature.State?
        @Presents var badges: BadgesFeature.State?

        var canSave: Bool {
            !displayName.trimmingCharacters(in: .whitespaces).isEmpty && !isSaving
        }

        /// Photo bytes shown on the card (pending preview or saved cutout).
        var cardPhotoData: Data? {
            pendingPhotoData ?? avatarImageData
        }

        var hasCardPhoto: Bool {
            cardPhotoData != nil
        }

        /// User picked a photo and must position it before cutout processing runs.
        var isAwaitingPhotoFix: Bool {
            pendingPhotoData != nil && !isProcessingPhoto
        }

        /// Show "Fijar imagen" — new pick or saved photo that never got a cutout.
        var showsPhotoFixButton: Bool {
            !isProcessingPhoto && !isPhotoPlacementLocked && photoNeedsBackgroundRemoval && hasCardPhoto
        }

        var canAdjustCardPhoto: Bool {
            hasCardPhoto && !isProcessingPhoto && !isPhotoPlacementLocked
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
                initials: ProfileFormatting.initials(from: name),
                avatarImageData: cardPhotoData,
                isPendingPhotoPlacement: pendingPhotoData != nil,
                photoPlacement: photoPlacement
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
        case heightUnitChanged(HeightUnit)
        case weightUnitChanged(WeightUnit)
        case photoSelected(Data)
        case photoFixTapped
        case photoProcessed(Data?)
        case photoPlacementChanged(PlayerCardPhotoPlacement)
        case photoAdjustTapped
        case photoAdjustFinished
        case photoRemoved
        case countryCodeChanged(String)
        case errorDismissed
        case courtsTapped
        case courts(PresentationAction<CourtsFeature.Action>)
        case badgesTapped
        case badges(PresentationAction<BadgesFeature.Action>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case signOut
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
                return .run { send in
                    await send(.sessionsForCardResponse(Result {
                        try await apiClient.listSessions(token)
                    }.mapError { $0 as? APIError ?? .invalidResponse }))
                }

            case .saveResponse(.failure):
                state.isSaving = false
                state.errorMessage = "Could not save your profile."
                return Self.scheduleErrorDismiss()

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
                guard state.profile?.id != nil else { return .none }
                ProfilePhotoLog.info("photoSelected: \(data.count) bytes")
                state.pendingPhotoData = data
                state.photoPlacement = .default
                state.isPhotoPlacementLocked = false
                state.isProcessingPhoto = false
                state.photoNeedsBackgroundRemoval = true
                state.errorMessage = nil
                return .none

            case .photoFixTapped:
                guard state.profile?.id != nil else { return .none }
                guard let source = state.pendingPhotoData ?? state.avatarImageData,
                      state.photoNeedsBackgroundRemoval
                else {
                    ProfilePhotoLog.error("photoFixTapped: skipped — no source or cutout not needed")
                    return .none
                }
                ProfilePhotoLog.info("photoFixTapped: starting cutout")
                state.isProcessingPhoto = true
                state.isPhotoPlacementLocked = true
                state.errorMessage = nil
                return Self.cutoutPhotoEffect(from: source)

            case let .photoProcessed(data):
                state.isProcessingPhoto = false
                guard let userId = state.profile?.id else { return .none }
                guard let data, let saved = ProfilePhotoStore.save(userId: userId, pngData: data) else {
                    ProfilePhotoLog.error("photoProcessed: save failed or nil data")
                    state.isPhotoPlacementLocked = false
                    state.errorMessage = BackgroundRemover.isSimulator
                        ? "El recorte de fondo no funciona en el Simulador. Prueba en un iPhone físico."
                        : "Could not cut out your photo. Try another image."
                    return Self.scheduleErrorDismiss()
                }
                ProfilePhotoLog.info("photoProcessed: saved cutout \(saved.count) bytes")
                state.avatarImageData = saved
                state.pendingPhotoData = nil
                state.photoNeedsBackgroundRemoval = false
                ProfilePhotoPlacementStore.save(userId: userId, placement: state.photoPlacement)
                state.isPhotoPlacementLocked = true
                ProfilePhotoPlacementLockStore.save(userId: userId, locked: true)
                return .none

            case let .photoPlacementChanged(placement):
                guard !state.isPhotoPlacementLocked else { return .none }
                state.photoPlacement = placement.clamped()
                if state.pendingPhotoData == nil, let userId = state.profile?.id {
                    ProfilePhotoPlacementStore.save(userId: userId, placement: state.photoPlacement)
                }
                return .none

            case .photoAdjustTapped:
                guard state.hasCardPhoto, let userId = state.profile?.id else { return .none }
                ProfilePhotoLog.info(
                    "photoAdjustTapped: needsRemoval=\(state.photoNeedsBackgroundRemoval)"
                )
                state.isPhotoPlacementLocked = false
                ProfilePhotoPlacementLockStore.save(userId: userId, locked: false)
                return .none

            case .photoAdjustFinished:
                guard state.hasCardPhoto, let userId = state.profile?.id else { return .none }
                ProfilePhotoLog.info(
                    "photoAdjustFinished: needsRemoval=\(state.photoNeedsBackgroundRemoval) "
                        + "pending=\(state.pendingPhotoData != nil)"
                )
                if state.photoNeedsBackgroundRemoval {
                    guard let source = state.pendingPhotoData ?? state.avatarImageData else {
                        ProfilePhotoLog.error("photoAdjustFinished: needs cutout but no image data")
                        return .none
                    }
                    ProfilePhotoLog.info("photoAdjustFinished: running cutout")
                    state.isProcessingPhoto = true
                    state.isPhotoPlacementLocked = true
                    state.errorMessage = nil
                    return Self.cutoutPhotoEffect(from: source)
                }
                state.isPhotoPlacementLocked = true
                ProfilePhotoPlacementStore.save(userId: userId, placement: state.photoPlacement)
                ProfilePhotoPlacementLockStore.save(userId: userId, locked: true)
                ProfilePhotoLog.info("photoAdjustFinished: placement locked")
                return .none

            case .photoRemoved:
                guard let userId = state.profile?.id else { return .none }
                ProfilePhotoLog.info("photoRemoved")
                ProfilePhotoStore.delete(userId: userId)
                ProfilePhotoPlacementStore.delete(userId: userId)
                ProfilePhotoPlacementLockStore.delete(userId: userId)
                state.avatarImageData = nil
                state.pendingPhotoData = nil
                state.photoPlacement = .default
                state.isPhotoPlacementLocked = false
                state.isProcessingPhoto = false
                state.photoNeedsBackgroundRemoval = false
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
        birthDate = profile.birthYear.map { ProfileBirthDate.date(fromBirthYear: $0) }
        avatarImageData = ProfilePhotoStore.load(userId: profile.id)
        if let data = avatarImageData {
            photoNeedsBackgroundRemoval = !ProfilePhotoProcessor.hasTransparentBackground(data)
            ProfilePhotoLog.info(
                "apply: loaded avatar \(data.count) bytes, needsRemoval=\(photoNeedsBackgroundRemoval)"
            )
        } else {
            photoNeedsBackgroundRemoval = false
        }
        photoPlacement = ProfilePhotoPlacementStore.load(userId: profile.id)
        isPhotoPlacementLocked = ProfilePhotoPlacementLockStore.isLocked(
            userId: profile.id,
            hasPhoto: avatarImageData != nil
        )
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
            birthYear: ProfileBirthDate.birthYear(from: birthDate)
        )
    }

}

private extension ProfileFeature {
    static func cutoutPhotoEffect(from data: Data) -> Effect<Action> {
        .run { send in
            ProfilePhotoLog.info("cutoutEffect: prepareForCard (\(data.count) bytes)")
            let prepared = await ProfilePhotoProcessor.prepareForCard(data)
            await send(.photoProcessed(prepared))
        }
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
    let avatarImageData: Data?
    /// True while the user is positioning a raw photo before cutout processing.
    let isPendingPhotoPlacement: Bool
    let photoPlacement: PlayerCardPhotoPlacement
}
