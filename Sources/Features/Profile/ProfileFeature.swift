import ComposableArchitecture
import Foundation

/// Loads and edits the authenticated user's profile via the backend.
@Reducer
struct ProfileFeature {
    @ObservableState
    struct State: Equatable {
        let accessToken: String
        var profile: Profile?
        var isLoading = false
        var isSaving = false
        var errorMessage: String?

        // Editable fields, mirrored from the loaded profile.
        var displayName = ""
        var preferredPosition = ""
        var heightText = ""
        var weightText = ""

        var canSave: Bool {
            !displayName.trimmingCharacters(in: .whitespaces).isEmpty && !isSaving
        }
    }

    enum Action: BindableAction, Equatable {
        case onAppear
        case binding(BindingAction<State>)
        case loadResponse(Result<Profile, APIError>)
        case saveTapped
        case saveResponse(Result<Profile, APIError>)
        case signOutTapped
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
                guard state.profile == nil else { return .none }
                state.isLoading = true
                state.errorMessage = nil
                let token = state.accessToken
                return .run { send in
                    await send(.loadResponse(Result { try await apiClient.me(token) }
                        .mapError { $0 as? APIError ?? .invalidResponse }))
                }

            case let .loadResponse(.success(profile)):
                state.isLoading = false
                state.apply(profile)
                return .none

            case .loadResponse(.failure):
                state.isLoading = false
                state.errorMessage = "Could not load your profile."
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
                return .none

            case .saveResponse(.failure):
                state.isSaving = false
                state.errorMessage = "Could not save your profile."
                return .none

            case .signOutTapped:
                return .send(.delegate(.signOut))

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
        heightText = profile.heightCm.map(String.init) ?? ""
        weightText = profile.weightKg.map { String(format: "%g", $0) } ?? ""
    }

    /// Builds the update payload from the editable fields.
    func makeUpdate() -> ProfileUpdate {
        let position = preferredPosition.trimmingCharacters(in: .whitespaces)
        return ProfileUpdate(
            displayName: displayName.trimmingCharacters(in: .whitespaces),
            preferredPosition: position.isEmpty ? nil : position,
            heightCm: Int(heightText.trimmingCharacters(in: .whitespaces)),
            weightKg: Double(weightText.trimmingCharacters(in: .whitespaces))
        )
    }
}
