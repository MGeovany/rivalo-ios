import Foundation

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
        case "duration_s": return "clock"
        case "speed_max_kmh": return "speedometer"
        case "sprints": return "bolt.fill"
        case "intensity": return "flame.fill"
        case "match_rating": return "star.fill"
        case "hr_max": return "heart.fill"
        case "calories_kcal": return "bolt"
        default: return "trophy.fill"
        }
    }
}
