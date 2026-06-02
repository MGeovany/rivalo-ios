import Foundation

struct Goal: Identifiable, Equatable, Codable {
    let id: String
    let userId: String
    let metric: String
    let period: String
    let target: Double
    let createdAt: Date
    let achievedAt: Date?
    let archived: Bool
    let progress: Double

    var isAchieved: Bool { achievedAt != nil }
    var progressFraction: Double {
        guard target > 0 else { return isAchieved ? 1 : 0 }
        return min(progress / target, 1)
    }
    var metricLabel: String {
        switch metric {
        case "distance": return "Distance"
        case "matches": return "Matches"
        case "sprints": return "Sprints"
        case "rating": return "Rating"
        default: return metric
        }
    }
    var periodLabel: String {
        switch period {
        case "week": return "per week"
        case "month": return "per month"
        default: return period
        }
    }
    var metricUnit: String {
        switch metric {
        case "distance": return "km"
        case "matches": return ""
        case "sprints": return ""
        case "rating": return ""
        default: return ""
        }
    }
    var progressDisplay: String {
        switch metric {
        case "distance":
            return "\(String(format: "%.1f", progress / 1000))/\(String(format: "%.1f", target / 1000)) km"
        case "matches":
            return "\(Int(progress))/\(Int(target))"
        case "sprints":
            return "\(Int(progress))/\(Int(target))"
        case "rating":
            return "\(String(format: "%.0f", progress))/\(String(format: "%.0f", target))"
        default:
            return "\(String(format: "%.1f", progress))/\(String(format: "%.1f", target))"
        }
    }
}

struct NewGoal: Equatable, Codable {
    let metric: String
    let period: String
    let target: Double
}

struct GoalUpdate: Equatable, Codable {
    let metric: String?
    let period: String?
    let target: Double?
    let archived: Bool?
}
