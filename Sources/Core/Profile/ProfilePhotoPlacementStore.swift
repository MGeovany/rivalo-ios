import CoreGraphics
import Foundation

/// Normalized pan/zoom for the player cutout on the card (fractions of card size).
struct PlayerCardPhotoPlacement: Equatable, Codable {
    var offsetX: CGFloat
    var offsetY: CGFloat
    var scale: CGFloat

    static let `default` = PlayerCardPhotoPlacement(offsetX: 0, offsetY: 0, scale: 1)

    func clamped() -> PlayerCardPhotoPlacement {
        PlayerCardPhotoPlacement(
            offsetX: min(0.42, max(-0.42, offsetX)),
            offsetY: min(0.38, max(-0.38, offsetY)),
            scale: min(2.0, max(0.55, scale))
        )
    }
}

enum ProfilePhotoPlacementStore {
    private static let keyPrefix = "rivalo.profile.photoPlacement."

    static func load(userId: String) -> PlayerCardPhotoPlacement {
        guard
            let data = UserDefaults.standard.data(forKey: keyPrefix + userId),
            let placement = try? JSONDecoder().decode(PlayerCardPhotoPlacement.self, from: data)
        else {
            return .default
        }
        return placement.clamped()
    }

    static func save(userId: String, placement: PlayerCardPhotoPlacement) {
        let clamped = placement.clamped()
        guard let data = try? JSONEncoder().encode(clamped) else { return }
        UserDefaults.standard.set(data, forKey: keyPrefix + userId)
    }

    static func delete(userId: String) {
        UserDefaults.standard.removeObject(forKey: keyPrefix + userId)
    }
}
