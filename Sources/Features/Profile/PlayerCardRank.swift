import SwiftUI

/// LoL-style ranked tiers — one tier every 5 logged matches; Holographic replaces Master+.
enum PlayerCardRank: String, Equatable, CaseIterable {
    case unranked
    case bronze
    case silver
    case gold
    case platinum
    case emerald
    case diamond
    case holographic

    static let matchesPerTier = 5
    private static let rankedLadder: [PlayerCardRank] = [
        .bronze, .silver, .gold, .platinum, .emerald, .diamond, .holographic,
    ]

    var displayName: String {
        switch self {
        case .unranked: "Sin clasificar"
        case .holographic: "Holográfico"
        default: rawValue.capitalized
        }
    }

    var isHolographic: Bool { self == .holographic }

    /// Resolves tier from total match count (5 matches per tier after placement).
    static func resolve(matchCount: Int) -> PlayerCardRank {
        guard matchCount >= matchesPerTier else { return .unranked }
        let tierIndex = min((matchCount - matchesPerTier) / matchesPerTier, rankedLadder.count - 1)
        return rankedLadder[tierIndex]
    }

    /// Matches logged within the current tier (1…5). Unranked uses progress toward Bronze.
    static func tierProgress(matchCount: Int) -> Int {
        guard matchCount > 0 else { return 0 }
        if matchCount < matchesPerTier { return matchCount }
        if resolve(matchCount: matchCount) == .holographic { return matchesPerTier }
        return ((matchCount - matchesPerTier) % matchesPerTier) + 1
    }

    /// Label for the next tier, if any.
    func nextRank() -> PlayerCardRank? {
        guard let index = Self.rankedLadder.firstIndex(of: self), index + 1 < Self.rankedLadder.count else {
            return nil
        }
        return Self.rankedLadder[index + 1]
    }

    var style: PlayerCardRankStyle {
        switch self {
        case .unranked:
            return PlayerCardRankStyle(
                frameTop: Color(red: 0.42, green: 0.44, blue: 0.48),
                frameMid: Color(red: 0.28, green: 0.30, blue: 0.34),
                frameDeep: Color(red: 0.14, green: 0.15, blue: 0.17),
                accent: Color(red: 0.62, green: 0.64, blue: 0.68),
                accentBright: Color(red: 0.78, green: 0.80, blue: 0.84),
                glow: Color.white.opacity(0.08),
                innerTint: Color(red: 0.08, green: 0.08, blue: 0.09),
                ratingGradient: [Color(red: 0.72, green: 0.74, blue: 0.78), Color(red: 0.48, green: 0.50, blue: 0.54)]
            )
        case .bronze:
            return PlayerCardRankStyle(
                frameTop: Color(red: 0.82, green: 0.58, blue: 0.38),
                frameMid: Color(red: 0.62, green: 0.38, blue: 0.18),
                frameDeep: Color(red: 0.38, green: 0.22, blue: 0.10),
                accent: Color(red: 0.88, green: 0.62, blue: 0.38),
                accentBright: Color(red: 0.95, green: 0.78, blue: 0.52),
                glow: Color(red: 0.82, green: 0.52, blue: 0.28).opacity(0.35),
                innerTint: Color(red: 0.10, green: 0.07, blue: 0.05),
                ratingGradient: [Color(red: 0.95, green: 0.78, blue: 0.52), Color(red: 0.72, green: 0.42, blue: 0.18)]
            )
        case .silver:
            return PlayerCardRankStyle(
                frameTop: Color(red: 0.88, green: 0.90, blue: 0.94),
                frameMid: Color(red: 0.58, green: 0.62, blue: 0.68),
                frameDeep: Color(red: 0.32, green: 0.34, blue: 0.38),
                accent: Color(red: 0.82, green: 0.86, blue: 0.92),
                accentBright: Color.white,
                glow: Color.white.opacity(0.22),
                innerTint: Color(red: 0.07, green: 0.08, blue: 0.10),
                ratingGradient: [Color.white, Color(red: 0.62, green: 0.66, blue: 0.72)]
            )
        case .gold:
            return PlayerCardRankStyle(
                frameTop: Color(red: 1, green: 0.92, blue: 0.55),
                frameMid: Color(red: 0.92, green: 0.68, blue: 0.18),
                frameDeep: Color(red: 0.58, green: 0.34, blue: 0.04),
                accent: Theme.Colors.accentBright,
                accentBright: Color(red: 1, green: 0.94, blue: 0.62),
                glow: Theme.Colors.accent.opacity(0.4),
                innerTint: Color(red: 0.09, green: 0.06, blue: 0.03),
                ratingGradient: [Theme.Colors.accentBright, Theme.Colors.accent]
            )
        case .platinum:
            return PlayerCardRankStyle(
                frameTop: Color(red: 0.62, green: 0.92, blue: 0.95),
                frameMid: Color(red: 0.28, green: 0.72, blue: 0.82),
                frameDeep: Color(red: 0.12, green: 0.42, blue: 0.52),
                accent: Color(red: 0.45, green: 0.88, blue: 0.95),
                accentBright: Color(red: 0.72, green: 0.98, blue: 1),
                glow: Color(red: 0.35, green: 0.85, blue: 0.95).opacity(0.35),
                innerTint: Color(red: 0.04, green: 0.08, blue: 0.10),
                ratingGradient: [Color(red: 0.72, green: 0.98, blue: 1), Color(red: 0.28, green: 0.72, blue: 0.82)]
            )
        case .emerald:
            return PlayerCardRankStyle(
                frameTop: Color(red: 0.45, green: 0.95, blue: 0.62),
                frameMid: Color(red: 0.18, green: 0.72, blue: 0.42),
                frameDeep: Color(red: 0.08, green: 0.42, blue: 0.24),
                accent: Color(red: 0.35, green: 0.92, blue: 0.55),
                accentBright: Color(red: 0.65, green: 1, blue: 0.75),
                glow: Color(red: 0.25, green: 0.85, blue: 0.45).opacity(0.35),
                innerTint: Color(red: 0.04, green: 0.09, blue: 0.06),
                ratingGradient: [Color(red: 0.65, green: 1, blue: 0.75), Color(red: 0.18, green: 0.72, blue: 0.42)]
            )
        case .diamond:
            return PlayerCardRankStyle(
                frameTop: Color(red: 0.82, green: 0.92, blue: 1),
                frameMid: Color(red: 0.45, green: 0.72, blue: 0.98),
                frameDeep: Color(red: 0.18, green: 0.38, blue: 0.72),
                accent: Color(red: 0.55, green: 0.82, blue: 1),
                accentBright: Color.white,
                glow: Color(red: 0.45, green: 0.72, blue: 1).opacity(0.45),
                innerTint: Color(red: 0.05, green: 0.07, blue: 0.12),
                ratingGradient: [Color.white, Color(red: 0.45, green: 0.72, blue: 0.98)]
            )
        case .holographic:
            return PlayerCardRankStyle(
                frameTop: Color(red: 1, green: 0.85, blue: 0.95),
                frameMid: Color(red: 0.55, green: 0.75, blue: 1),
                frameDeep: Color(red: 0.72, green: 0.35, blue: 0.95),
                accent: Color(red: 1, green: 0.55, blue: 0.85),
                accentBright: Color.white,
                glow: Color(red: 0.85, green: 0.45, blue: 1).opacity(0.5),
                innerTint: Color(red: 0.06, green: 0.05, blue: 0.10),
                ratingGradient: [
                    Color(red: 1, green: 0.55, blue: 0.85),
                    Color(red: 0.55, green: 0.85, blue: 1),
                    Color(red: 1, green: 0.92, blue: 0.45),
                ]
            )
        }
    }
}

struct PlayerCardRankStyle {
    let frameTop: Color
    let frameMid: Color
    let frameDeep: Color
    let accent: Color
    let accentBright: Color
    let glow: Color
    let innerTint: Color
    let ratingGradient: [Color]

    var frameGradient: LinearGradient {
        LinearGradient(
            colors: [frameTop, frameMid, frameDeep, frameMid, frameTop],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var borderGradient: LinearGradient {
        LinearGradient(
            colors: [frameTop.opacity(0.85), frameDeep.opacity(0.5), accent.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var ratingForeground: LinearGradient {
        LinearGradient(colors: ratingGradient, startPoint: .top, endPoint: .bottom)
    }
}
