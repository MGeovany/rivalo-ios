import Foundation

/// Local pitch draft until `POST /v1/pitches` (V2-F.1).
struct PitchDraft: Equatable, Codable, Sendable {
    var id: String
    var name: String
    var lengthM: Double
    var widthM: Double
    var measurementMethod: String
    var latitude: Double?
    var longitude: Double?

    init(
        id: String = UUID().uuidString,
        name: String,
        lengthM: Double,
        widthM: Double,
        measurementMethod: String,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.lengthM = lengthM
        self.widthM = widthM
        self.measurementMethod = measurementMethod
        self.latitude = latitude
        self.longitude = longitude
    }
}

enum PitchDraftStore {
    private static let key = "rivalo.pitch.drafts.v1"

    static func all() -> [PitchDraft] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let drafts = try? JSONDecoder().decode([PitchDraft].self, from: data)
        else { return [] }
        return drafts
    }

    static func save(_ draft: PitchDraft) {
        var drafts = all()
        if let index = drafts.firstIndex(where: { $0.id == draft.id }) {
            drafts[index] = draft
        } else {
            drafts.append(draft)
        }
        guard let data = try? JSONEncoder().encode(drafts) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
