import SwiftUI

/// Visual theme for Rivalo: a modern, dark, sporty look shared across screens.
enum Theme {
    enum Colors {
        /// Near-black app background.
        static let background = Color(red: 0.05, green: 0.06, blue: 0.07)
        /// Elevated surface (cards, sheets) in dark gray.
        static let surface = Color(red: 0.11, green: 0.12, blue: 0.14)
        /// Vibrant sporty accent used for primary actions and highlights.
        static let accent = Color(red: 0.0, green: 0.85, blue: 0.45)
        /// Primary text on dark surfaces.
        static let textPrimary = Color.white
        /// Secondary, lower-emphasis text.
        static let textSecondary = Color(white: 0.65)
        /// Positive / healthy status.
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
            .custom(Family.logo, size: size)
        }

        /// Screen titles and prominent headings (Rajdhani).
        static func title(size: CGFloat = 22) -> Font {
            .custom(Family.rajdhaniSemiBold, size: size)
        }

        /// Primary buttons (Rajdhani).
        static func button(size: CGFloat = 16) -> Font {
            .custom(Family.rajdhaniSemiBold, size: size)
        }

        static func body(size: CGFloat = 16) -> Font {
            .custom(Family.rajdhaniRegular, size: size)
        }

        static func caption(size: CGFloat = 13) -> Font {
            .custom(Family.rajdhaniMedium, size: size)
        }

        /// Headline metrics and stat values (Space Mono).
        static func metric(size: CGFloat = 44) -> Font {
            .custom(Family.spaceMonoBold, size: size)
        }

        /// Secondary stat labels (Space Mono).
        static func statLabel(size: CGFloat = 13) -> Font {
            .custom(Family.spaceMonoRegular, size: size)
        }
    }

    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
    }

    enum Radius {
        static let card: CGFloat = 16
    }
}
