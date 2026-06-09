import ComposableArchitecture
import Foundation

/// Create or edit a court: all fields plus device-local photos.
@Reducer
struct CourtEditFeature {
    @ObservableState
    struct State: Equatable, Identifiable {
        var accessToken: String
        /// nil id means we are creating a new court (photos enabled after first save).
        var pitchId: String?
        var name = ""
        var type = ""
        var surface = ""
        var lengthText = ""
        var widthText = ""
        /// Pitch orientation (own goal -> rival goal), degrees from north. Optional.
        var headingDeg: Double?
        /// Pitch center, captured alongside orientation; needed for geo-projection.
        var latitude: Double?
        var longitude: Double?
        var indoor = false
        var notes = ""
        var photos: [PitchPhoto] = []
        var stats: PitchStats?
        var isSaving = false
        var errorMessage: String?

        var id: String { pitchId ?? "new" }
        var isEditing: Bool { pitchId != nil }
        var canSave: Bool { !isSaving && !name.trimmingCharacters(in: .whitespaces).isEmpty }

        init(accessToken: String) {
            self.accessToken = accessToken
        }

        init(accessToken: String, pitch: Pitch) {
            self.accessToken = accessToken
            self.pitchId = pitch.id
            self.name = pitch.name
            self.type = pitch.type ?? ""
            self.surface = pitch.surface ?? ""
            self.lengthText = pitch.lengthM.map { String(format: "%.0f", $0) } ?? ""
            self.widthText = pitch.widthM.map { String(format: "%.0f", $0) } ?? ""
            self.headingDeg = pitch.headingDeg
            self.latitude = pitch.latitude
            self.longitude = pitch.longitude
            self.indoor = pitch.indoor ?? false
            self.notes = pitch.notes ?? ""
            self.photos = PitchPhotoStore.load(pitchId: pitch.id)
        }
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case statsResponse(Result<PitchStats, APIError>)
        case saveTapped
        case saveResponse(Result<Pitch, APIError>)
        case deleteTapped
        case deleteResponse(Result<String, APIError>)
        case photoAdded(Data)
        case photoDeleted(String)
        case dismissTapped
        case delegate(Delegate)

        enum Delegate: Equatable {
            case saved
            case deleted
            case dismissed
        }
    }

    @Dependency(\.apiClient) var apiClient

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .onAppear:
                guard let id = state.pitchId else { return .none }
                let token = state.accessToken
                return .run { send in
                    await send(.statsResponse(Result { try await apiClient.fetchPitchStats(token, id) }
                        .mapError { $0 as? APIError ?? .invalidResponse }))
                }

            case let .statsResponse(.success(stats)):
                state.stats = stats
                return .none

            case .statsResponse(.failure):
                return .none

            case .saveTapped:
                guard state.canSave else { return .none }
                state.isSaving = true
                state.errorMessage = nil
                let token = state.accessToken
                let id = state.pitchId

                let length = Double(state.lengthText)
                let width = Double(state.widthText)
                let name = state.name.trimmingCharacters(in: .whitespaces)
                let type = state.type.isEmpty ? nil : state.type
                let surface = state.surface.isEmpty ? nil : state.surface
                let notes = state.notes.isEmpty ? nil : state.notes
                let indoor = state.indoor

                let headingDeg = state.headingDeg
                let latitude = state.latitude
                let longitude = state.longitude

                if let id {
                    let update = PitchUpdate(
                        name: name, latitude: latitude, longitude: longitude, type: type, surface: surface,
                        lengthM: length, widthM: width, headingDeg: headingDeg, indoor: indoor, notes: notes
                    )
                    return .run { send in
                        await send(.saveResponse(Result { try await apiClient.updatePitch(token, id, update) }
                            .mapError { $0 as? APIError ?? .invalidResponse }))
                    }
                } else {
                    let new = NewPitch(
                        name: name, latitude: latitude, longitude: longitude, type: type, surface: surface,
                        lengthM: length, widthM: width, headingDeg: headingDeg, indoor: indoor, notes: notes
                    )
                    return .run { send in
                        await send(.saveResponse(Result { try await apiClient.createPitch(token, new) }
                            .mapError { $0 as? APIError ?? .invalidResponse }))
                    }
                }

            case let .saveResponse(.success(pitch)):
                state.isSaving = false
                // Keep the id so photos attach to a real court after a create.
                state.pitchId = pitch.id
                return .send(.delegate(.saved))

            case .saveResponse(.failure):
                state.isSaving = false
                state.errorMessage = "Could not save the court."
                return .none

            case .deleteTapped:
                guard let id = state.pitchId else { return .send(.delegate(.dismissed)) }
                let token = state.accessToken
                return .run { send in
                    await send(.deleteResponse(Result { try await apiClient.deletePitch(token, id); return id }
                        .mapError { $0 as? APIError ?? .invalidResponse }))
                }

            case let .deleteResponse(.success(id)):
                PitchPhotoStore.deleteAll(pitchId: id)
                return .send(.delegate(.deleted))

            case .deleteResponse(.failure):
                state.errorMessage = "Could not delete the court."
                return .none

            case let .photoAdded(data):
                guard let id = state.pitchId else { return .none }
                _ = PitchPhotoStore.append(pitchId: id, rawImageData: data)
                state.photos = PitchPhotoStore.load(pitchId: id)
                return .none

            case let .photoDeleted(photoId):
                guard let id = state.pitchId else { return .none }
                PitchPhotoStore.delete(pitchId: id, photoId: photoId)
                state.photos = PitchPhotoStore.load(pitchId: id)
                return .none

            case .dismissTapped:
                return .send(.delegate(.dismissed))

            case .delegate:
                return .none
            }
        }
    }
}
