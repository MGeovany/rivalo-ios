import SwiftUI
import UIKit

/// Renders a player card view to a shareable bitmap at the native 1024×1536 canvas.
enum PlayerCardExporter {
    @MainActor
    static func renderImage(
        content: PlayerCardContent,
        images: [PlayerCardLayer: UIImage],
        scale: CGFloat = 2
    ) -> UIImage? {
        let size = CGSize(width: PlayerCardLayout.canvasWidth, height: PlayerCardLayout.canvasHeight)
        let canvas = PlayerProgressCardCanvas(
            content: content,
            canvasSize: size,
            images: images
        )
        .frame(width: size.width, height: size.height)
        .clipped()

        let renderer = ImageRenderer(content: canvas)
        renderer.scale = scale
        renderer.isOpaque = false
        return renderer.uiImage
    }

    @MainActor
    static func renderPNGData(
        content: PlayerCardContent,
        images: [PlayerCardLayer: UIImage],
        scale: CGFloat = 2
    ) -> Data? {
        renderImage(content: content, images: images, scale: scale)?.pngData()
    }
}
