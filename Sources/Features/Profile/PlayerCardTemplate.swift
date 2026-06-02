import CoreGraphics
import SwiftUI

/// Layer identifiers for player card PNGs hosted in Supabase Storage.
enum PlayerCardLayer: String, CaseIterable {
    case background
    case frame
    case fxOverlay = "fx-overlay"
    case photoMask = "photo-mask-soft"

    var fileName: String { "\(rawValue).png" }
}

enum PlayerCardTierAssets {
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
}

/// Normalized layout from `layout-guide.json` (also stored in Supabase for designers).
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
    /// Mirrored inset from the right frame edge (same 15% margin as left column).
    static let rightStats = SafeArea(x: 0.67, y: 0.55, width: 0.18, height: 0.23)
    static let playerName = SafeArea(x: 0.20, y: 0.79, width: 0.60, height: 0.09)
    static let tierLabel = SafeArea(x: 0.34, y: 0.90, width: 0.32, height: 0.05)
}
