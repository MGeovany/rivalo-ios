import SwiftUI

/// Asset catalog names for rank card frame templates (1024×1536).
enum PlayerCardTemplate {
    static func assetName(for rank: PlayerCardRank) -> String {
        switch rank {
        case .unranked, .bronze: "PlayerCardBronze"
        case .silver: "PlayerCardSilver"
        case .gold: "PlayerCardGold"
        case .platinum: "PlayerCardPlatinum"
        case .emerald: "PlayerCardEmerald"
        case .diamond: "PlayerCardDiamond"
        case .holographic: "PlayerCardHolographic"
        }
    }
}

/// Normalized layout coordinates for overlays on the 1024×1536 templates.
enum PlayerCardLayout {
    static let aspectRatio: CGFloat = 1024.0 / 1536.0

    static let photoAnchorX: CGFloat = 0.5
    static let photoAnchorY: CGFloat = 0.39
    static let photoMaxWidth: CGFloat = 0.84
    static let photoMaxHeight: CGFloat = 0.56

    static let ratingX: CGFloat = 0.11
    static let ratingY: CGFloat = 0.11
    static let flagX: CGFloat = 0.89
    static let flagY: CGFloat = 0.115

    static let statsLeftX: CGFloat = 0.13
    static let statsRightX: CGFloat = 0.87
    static let statsY: CGFloat = 0.545

    static let nameY: CGFloat = 0.735
    static let tierLabelY: CGFloat = 0.885
}
