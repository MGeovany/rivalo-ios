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
        /// Large emphasized number used for headline metrics.
        static func metric() -> Font { .system(size: 44, weight: .bold, design: .rounded) }
        static func title() -> Font { .system(size: 22, weight: .semibold, design: .rounded) }
        static func body() -> Font { .system(size: 16, weight: .regular, design: .rounded) }
        static func caption() -> Font { .system(size: 13, weight: .medium, design: .rounded) }
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
