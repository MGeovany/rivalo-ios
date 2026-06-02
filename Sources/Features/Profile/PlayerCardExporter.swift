import SwiftUI
import UIKit

/// Renders a player card view to a shareable bitmap.
enum PlayerCardExporter {
    @MainActor
    static func renderImage(
        from view: some View,
        size: CGSize = CGSize(width: PlayerCardLayout.canvasWidth, height: PlayerCardLayout.canvasHeight),
        scale: CGFloat = 2
    ) -> UIImage? {
        let content = view
            .frame(width: size.width, height: size.height)
            .background(Color.black)

        let renderer = ImageRenderer(content: content)
        renderer.scale = scale
        return renderer.uiImage
    }

    @MainActor
    static func renderPNGData(
        from view: some View,
        size: CGSize = CGSize(width: PlayerCardLayout.canvasWidth, height: PlayerCardLayout.canvasHeight),
        scale: CGFloat = 2
    ) -> Data? {
        renderImage(from: view, size: size, scale: scale)?.pngData()
    }
}

extension PlayerProgressCard {
    @MainActor
    func exportImage(scale: CGFloat = 2) -> UIImage? {
        PlayerCardExporter.renderImage(from: self, scale: scale)
    }

    @MainActor
    func exportPNGData(scale: CGFloat = 2) -> Data? {
        PlayerCardExporter.renderPNGData(from: self, scale: scale)
    }
}
