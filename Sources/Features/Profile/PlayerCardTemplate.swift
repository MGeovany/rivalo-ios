import CoreGraphics
import SwiftUI
import UIKit

/// Layered player card assets stored under `PlayerCardAssets/<tier>/` in the app bundle.
enum PlayerCardLayer: String, CaseIterable {
    case background
    case frame
    case fxOverlay = "fx-overlay"
    case photoMask = "photo-mask-soft"

    var fileName: String { "\(rawValue).png" }
}

enum PlayerCardTierAssets {
    static let bundleSubdirectory = "PlayerCardAssets"

    static func tierFolder(for rank: PlayerCardRank) -> String {
        switch rank {
        case .unranked, .bronze: "bronze"
        case .silver: "silver"
        case .gold: "gold"
        case .platinum: "platinum"
        case .emerald: "emerald"
        case .diamond: "diamond"
        case .holographic: "holographic"
        }
    }

    static func image(for rank: PlayerCardRank, layer: PlayerCardLayer) -> Image {
        if let uiImage = uiImage(for: rank, layer: layer) {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "photo")
    }

    static func uiImage(for rank: PlayerCardRank, layer: PlayerCardLayer) -> UIImage? {
        let tier = tierFolder(for: rank)
        let resource = layer.rawValue
        let subdirectory = "\(bundleSubdirectory)/\(tier)"

        guard let url = Bundle.main.url(forResource: resource, withExtension: "png", subdirectory: subdirectory),
              let image = UIImage(contentsOfFile: url.path)
        else {
            return nil
        }
        return image
    }
}

/// Normalized layout from `PlayerCardAssets/layout-guide.json`.
enum PlayerCardLayout {
    static let canvasWidth: CGFloat = 1024
    static let canvasHeight: CGFloat = 1536
    static let aspectRatio: CGFloat = canvasWidth / canvasHeight

    struct SafeArea {
        let x: CGFloat
        let y: CGFloat
        let width: CGFloat
        let height: CGFloat

        func center(in size: CGSize) -> CGPoint {
            CGPoint(
                x: size.width * (x + width / 2),
                y: size.height * (y + height / 2)
            )
        }

        func frame(in size: CGSize) -> CGRect {
            CGRect(
                x: size.width * x,
                y: size.height * y,
                width: size.width * width,
                height: size.height * height
            )
        }
    }

    static let rating = SafeArea(x: 0.11, y: 0.08, width: 0.23, height: 0.17)
    static let position = SafeArea(x: 0.13, y: 0.23, width: 0.16, height: 0.07)
    static let country = SafeArea(x: 0.77, y: 0.08, width: 0.14, height: 0.11)
    static let portrait = SafeArea(x: 0.15, y: 0.13, width: 0.70, height: 0.62)
    static let leftStats = SafeArea(x: 0.15, y: 0.56, width: 0.18, height: 0.18)
    static let rightStats = SafeArea(x: 0.72, y: 0.55, width: 0.17, height: 0.23)
    static let playerName = SafeArea(x: 0.20, y: 0.79, width: 0.60, height: 0.09)
    static let tierLabel = SafeArea(x: 0.34, y: 0.90, width: 0.32, height: 0.05)
}
