import Foundation

/// Time window filters for the Activities list.
enum ActivityListFilter: String, CaseIterable, Identifiable, Equatable {
    case all = "All"
    case thisWeek = "This week"
    case thisMonth = "This month"

    var id: String { rawValue }

    func apply(_ sessions: [SportSession], reference: Date = Date()) -> [SportSession] {
        switch self {
        case .all:
            return sessions
        case .thisWeek:
            return PerformancePeriod.thisWeek.filter(sessions, reference: reference)
        case .thisMonth:
            return PerformancePeriod.thisMonth.filter(sessions, reference: reference)
        }
    }
}

extension SportSession {
    func matchesActivitySearch(_ query: String, venueName: String?) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return true }

        if startedAt.formatted(date: .abbreviated, time: .omitted).lowercased().contains(q) { return true }
        if startedAt.formatted(date: .complete, time: .omitted).lowercased().contains(q) { return true }

        if let venue = venueName?.lowercased(), venue.contains(q) { return true }
        if let matchType, matchType.lowercased().contains(q) { return true }
        if let surface, surface.lowercased().contains(q) { return true }
        if let position, position.lowercased().contains(q) { return true }
        if let result, result.lowercased().contains(q) { return true }
        if let tag = matchTag, tag.lowercased().contains(q) { return true }
        if distanceKmText.lowercased().contains(q) { return true }

        return false
    }
}
