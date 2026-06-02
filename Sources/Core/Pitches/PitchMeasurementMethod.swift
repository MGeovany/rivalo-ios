import Foundation

/// V2-F: how a pitch is measured (`walk` / `manual`).
enum PitchMeasurementMethod: String, Equatable, Codable, Sendable, CaseIterable, Identifiable {
    case walk
    case manual

    var id: String { rawValue }

    var title: String {
        switch self {
        case .walk: "Run the pitch"
        case .manual: "Manual entry"
        }
    }

    var subtitle: String {
        switch self {
        case .walk: "Jog or run the length and width — GPS tracks distance"
        case .manual: "Type length and width in meters"
        }
    }

    var systemImage: String {
        switch self {
        case .walk: "figure.run"
        case .manual: "ruler"
        }
    }

    var deviceHint: String {
        switch self {
        case .walk: "iPhone · Apple Watch"
        case .manual: "iPhone"
        }
    }

    init?(watchRawValue: String) {
        guard watchRawValue != "camera" else { return nil }
        self.init(rawValue: watchRawValue)
    }
}
