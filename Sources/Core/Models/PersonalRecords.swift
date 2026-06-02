import Foundation
import SwiftUI

struct PersonalRecords: Equatable, Codable, Sendable {
    var records: [RecordEntry]
}

struct RecordEntry: Equatable, Codable, Sendable, Identifiable {
    let metric: String
    let value: Double
    let sessionId: String
    let startedAt: Date

    var id: String { metric }

    var label: String {
        switch metric {
        case "distance_m": return "Distance"
        case "duration_s": return "Duration"
        case "speed_max_kmh": return "Top Speed"
        case "sprints": return "Sprints"
        case "intensity": return "Intensity"
        case "match_rating": return "Match Rating"
        case "hr_max": return "Max HR"
        case "calories_kcal": return "Calories"
        default: return metric
        }
    }

    var formattedValue: String {
        switch metric {
        case "distance_m":
            let km = value / 1000
            return String(format: "%.2f km", km)
        case "duration_s":
            let h = Int(value) / 3600
            let m = (Int(value) % 3600) / 60
            if h > 0 { return "\(h)h \(m)m" }
            return "\(m)m"
        case "speed_max_kmh":
            return String(format: "%.1f km/h", value)
        case "sprints":
            return "\(Int(value))"
        case "intensity":
            return String(format: "%.0f", value)
        case "match_rating":
            return String(format: "%.0f", value)
        case "hr_max":
            return "\(Int(value)) bpm"
        case "calories_kcal":
            return "\(Int(value)) kcal"
        default:
            return "\(value)"
        }
    }

    var icon: String {
        switch metric {
        case "distance_m": return "figure.run"
        case "duration_s": return "clock.fill"
        case "speed_max_kmh": return "speedometer"
        case "sprints": return "hare.fill"
        case "intensity": return "flame.fill"
        case "match_rating": return "star.fill"
        case "hr_max": return "heart.fill"
        case "calories_kcal": return "bolt.fill"
        default: return "trophy.fill"
        }
    }

    var accentColor: Color {
        switch metric {
        case "distance_m": return Theme.Colors.accentBright
        case "duration_s": return Theme.Colors.accent
        case "speed_max_kmh": return Color(red: 1, green: 0.85, blue: 0.35)
        case "sprints": return Theme.Colors.accent
        case "intensity": return Theme.Colors.accentBright
        case "match_rating": return Color(red: 0.45, green: 0.85, blue: 1)
        case "hr_max": return Color(red: 1, green: 0.45, blue: 0.45)
        case "calories_kcal": return Color(red: 1, green: 0.6, blue: 0.2)
        default: return Theme.Colors.accent
        }
    }
}
