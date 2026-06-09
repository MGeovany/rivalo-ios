import CoreGraphics
import Foundation

/// Pitch size and line layout by match format.
enum PitchFormat: Equatable, CaseIterable {
    case fiveASide
    case sevenASide
    case nineASide
    case elevenASide

    static func from(matchType: String?) -> PitchFormat {
        switch matchType {
        case "5-a-side": .fiveASide
        case "7-a-side": .sevenASide
        case "9-a-side": .nineASide
        case "11-a-side", "Other": .elevenASide
        default: .elevenASide
        }
    }

    var lengthM: Double {
        switch self {
        case .fiveASide: 40
        case .sevenASide: 60
        case .nineASide: 80
        case .elevenASide: 105
        }
    }

    var widthM: Double {
        switch self {
        case .fiveASide: 20
        case .sevenASide: 40
        case .nineASide: 50
        case .elevenASide: 68
        }
    }

    var aspect: CGFloat { CGFloat(lengthM / widthM) }

    /// Penalty area width as fraction of pitch width.
    var penaltyBoxWidthRatio: CGFloat {
        switch self {
        case .fiveASide: 0.55
        case .sevenASide: 0.48
        case .nineASide: 0.42
        case .elevenASide: 0.52
        }
    }

    /// Penalty area depth as fraction of pitch length (each end).
    var penaltyBoxDepthRatio: CGFloat {
        switch self {
        case .fiveASide: 0.14
        case .sevenASide: 0.15
        case .nineASide: 0.16
        case .elevenASide: 0.16
        }
    }

    var showsCenterCircle: Bool {
        switch self {
        case .fiveASide: false
        case .sevenASide, .nineASide, .elevenASide: true
        }
    }

    var centerCircleRadiusRatio: CGFloat {
        switch self {
        case .fiveASide: 0
        case .sevenASide: 0.10
        case .nineASide: 0.11
        case .elevenASide: 0.12
        }
    }

    var showsGoalAreas: Bool {
        self == .elevenASide
    }
}

enum PitchMapMode: String, CaseIterable, Identifiable {
    case heatmap = "Mapa de calor"
    case route = "Ruta"
    case sprints = "Sprints"

    var id: String { rawValue }
}

enum PitchMatchPeriod: String, CaseIterable, Identifiable {
    case full = "Partido completo"
    case firstHalf = "Primer tiempo"
    case secondHalf = "Segundo tiempo"

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .full: "Completo"
        case .firstHalf: "1er tiempo"
        case .secondHalf: "2do tiempo"
        }
    }
}
