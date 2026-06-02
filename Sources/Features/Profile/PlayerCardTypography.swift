import SwiftUI

/// Scaled typography for the 1024×1536 player card (matches preview-flat reference).
enum PlayerCardTypography {
    static func rating(size: CGFloat) -> Font {
        ThemeFont.font(name: "Rajdhani-Bold", size: size * 0.225)
    }

    static func position(size: CGFloat) -> Font {
        ThemeFont.font(name: "Rajdhani-SemiBold", size: size * 0.050)
    }

    static func statValue(size: CGFloat) -> Font {
        ThemeFont.font(name: "Rajdhani-Bold", size: size * 0.086)
    }

    static func statLabel(size: CGFloat) -> Font {
        ThemeFont.font(name: "Rajdhani-Medium", size: size * 0.026)
    }

    static func playerName(size: CGFloat) -> Font {
        ThemeFont.font(name: "Rajdhani-Bold", size: size * 0.092)
    }

    static func countryCode(size: CGFloat) -> Font {
        ThemeFont.font(name: "Rajdhani-SemiBold", size: size * 0.026)
    }
}
