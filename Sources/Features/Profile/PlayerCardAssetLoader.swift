import SwiftUI
import UIKit

/// Loads remote player card layer images for a tier into SwiftUI state.
@MainActor
@Observable
final class PlayerCardAssetLoader {
    private(set) var images: [PlayerCardLayer: UIImage] = [:]
    private(set) var isLoading = false

    func load(tier: PlayerCardRank) async {
        isLoading = true
        defer { isLoading = false }

        await withTaskGroup(of: (PlayerCardLayer, UIImage?).self) { group in
            for layer in PlayerCardLayer.allCases {
                group.addTask {
                    let image = await PlayerCardAssetStore.shared.uiImage(for: tier, layer: layer)
                    return (layer, image)
                }
            }

            var loaded: [PlayerCardLayer: UIImage] = [:]
            for await (layer, image) in group {
                if let image {
                    loaded[layer] = image
                }
            }
            images = loaded
        }
    }

    func image(for layer: PlayerCardLayer) -> UIImage? {
        images[layer]
    }
}
