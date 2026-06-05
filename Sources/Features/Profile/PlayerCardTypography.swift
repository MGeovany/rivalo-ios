import SwiftUI

/// Scaled typography for the 1024×1536 player card (matches preview-flat reference).
enum PlayerCardTypography {
    static func rating(size: CGFloat) -> Font {
        ThemeFont.font(name: "Rajdhani-Bold", size: size * 0.290)
    }

    static func position(size: CGFloat) -> Font {
        ThemeFont.font(name: "Rajdhani-SemiBold", size: size * 0.068)
    }

    static func statValue(size: CGFloat) -> Font {
        statValue(size: size, longestValueLength: 3)
    }

    static func statValue(size: CGFloat, longestValueLength: Int) -> Font {
        let scale: CGFloat = switch longestValueLength {
        case 6...: 0.064
        case 5...: 0.072
        case 4...: 0.080
        default: 0.086
        }
        return ThemeFont.font(name: "Rajdhani-Bold", size: size * scale)
    }

    static func statLabel(size: CGFloat) -> Font {
        ThemeFont.font(name: "Rajdhani-Medium", size: size * 0.042)
    }

    static func playerName(size: CGFloat) -> Font {
        ThemeFont.font(name: "Rajdhani-Bold", size: size * 0.092)
    }

    static func countryCode(size: CGFloat) -> Font {
        ThemeFont.font(name: "Rajdhani-SemiBold", size: size * 0.036)
    }

    /// `size` is the emblem diamond width, not the full card width.
    static func emblemInitials(size: CGFloat) -> Font {
        ThemeFont.font(name: "Rajdhani-Bold", size: size * 0.52)
    }
}
