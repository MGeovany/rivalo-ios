import Foundation

/// V2-F: how a pitch is measured (`walk` / `manual` on Apple Watch).
enum PitchMeasurementMethod: String, Equatable, Codable, Sendable, CaseIterable, Identifiable {
    case walk
    case manual

    var id: String { rawValue }

    /// Methods shown on the iPhone measure hub (manual is watch-only).
    static var iphoneHubCases: [PitchMeasurementMethod] { [.walk] }

    var title: String {
        switch self {
        case .walk: "Run the pitch"
        case .manual: "Manual"
        }
    }

    var subtitle: String {
        switch self {
        case .walk: "Jog or run the length and width — GPS on Apple Watch"
        case .manual: "Set meters on your Apple Watch"
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
        case .walk: "Apple Watch"
        case .manual: "Apple Watch"
        }
    }

    init?(watchRawValue: String) {
        guard watchRawValue != "camera" else { return nil }
        self.init(rawValue: watchRawValue)
    }
}
