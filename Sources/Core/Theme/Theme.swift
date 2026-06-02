import SwiftUI

/// Visual theme for Rivalo: a modern, dark, sporty look shared across screens.
enum Theme {
    enum Colors {
        /// Near-black app background (#040506).
        static let background = Color(red: 4 / 255, green: 5 / 255, blue: 6 / 255)
        /// Elevated surface (#242526).
        static let surface = Color(red: 36 / 255, green: 37 / 255, blue: 38 / 255)
        /// Brand primary orange (#FF5A00).
        static let accent = Color(red: 1.0, green: 90 / 255, blue: 0)
        /// Secondary orange highlight (#FF9D00).
        static let accentBright = Color(red: 1.0, green: 157 / 255, blue: 0)
        /// Primary text (#F5F5F5).
        static let textPrimary = Color(red: 245 / 255, green: 245 / 255, blue: 245 / 255)
        /// Secondary text (#666666).
        static let textSecondary = Color(red: 102 / 255, green: 102 / 255, blue: 102 / 255)
        /// Positive / healthy status (distinct from brand primary).
        static let positive = Color(red: 0.0, green: 0.85, blue: 0.45)
        /// Negative / error status.
        static let negative = Color(red: 0.95, green: 0.30, blue: 0.30)
    }

    enum Typography {
        private enum Family {
            static let logo = "Michroma-Regular"
            static let rajdhaniRegular = "Rajdhani-Regular"
            static let rajdhaniMedium = "Rajdhani-Medium"
            static let rajdhaniSemiBold = "Rajdhani-SemiBold"
            static let rajdhaniBold = "Rajdhani-Bold"
            static let spaceMonoRegular = "SpaceMono-Regular"
            static let spaceMonoBold = "SpaceMono-Bold"
        }

        /// Wordmark / logo (Michroma).
        static func logo(size: CGFloat = 28) -> Font {
            ThemeFont.font(name: Family.logo, size: size)
        }

        /// Screen titles and prominent headings (Rajdhani).
        static func title(size: CGFloat = 22) -> Font {
            ThemeFont.font(name: Family.rajdhaniSemiBold, size: size)
        }

        /// Primary buttons (Rajdhani).
        static func button(size: CGFloat = 16) -> Font {
            ThemeFont.font(name: Family.rajdhaniSemiBold, size: size)
        }

        static func body(size: CGFloat = 16) -> Font {
            ThemeFont.font(name: Family.rajdhaniRegular, size: size)
        }

        static func caption(size: CGFloat = 13) -> Font {
            ThemeFont.font(name: Family.rajdhaniMedium, size: size)
        }

        /// Headline metrics and stat values (Space Mono).
        static func metric(size: CGFloat = 44) -> Font {
            ThemeFont.font(name: Family.spaceMonoBold, size: size)
        }

        /// Secondary stat labels (Space Mono).
        static func statLabel(size: CGFloat = 13) -> Font {
            ThemeFont.font(name: Family.spaceMonoRegular, size: size)
        }
    }

    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
    }

    enum Radius {
        static let card: CGFloat = 16
        static let input: CGFloat = 12
    }
}
