import Foundation

// MARK: - Height

enum HeightUnit: String, CaseIterable, Identifiable, Equatable {
    case centimeters
    case meters
    case feet

    var id: String { rawValue }

    var menuLabel: String {
        switch self {
        case .centimeters: "cm"
        case .meters: "m"
        case .feet: "ft"
        }
    }

    var fieldLabel: String {
        switch self {
        case .centimeters: "Centímetros"
        case .meters: "Metros"
        case .feet: "Pies"
        }
    }

    static func loadPreferred() -> HeightUnit {
        guard let raw = UserDefaults.standard.string(forKey: Keys.height),
              let unit = HeightUnit(rawValue: raw) else { return .centimeters }
        return unit
    }

    func savePreferred() {
        UserDefaults.standard.set(rawValue, forKey: Keys.height)
    }

    func format(cm: Int?) -> String {
        guard let cm else { return "" }
        switch self {
        case .centimeters:
            return String(cm)
        case .meters:
            return String(format: "%.2f", Double(cm) / 100)
        case .feet:
            return String(format: "%.1f", Double(cm) / 30.48)
        }
    }

    func parseToCm(_ text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let value = Double(trimmed.replacingOccurrences(of: ",", with: ".")) else {
            return nil
        }
        switch self {
        case .centimeters:
            return Int(value.rounded())
        case .meters:
            return Int((value * 100).rounded())
        case .feet:
            return Int((value * 30.48).rounded())
        }
    }
}

// MARK: - Weight

enum WeightUnit: String, CaseIterable, Identifiable, Equatable {
    case kilograms
    case pounds

    var id: String { rawValue }

    var menuLabel: String {
        switch self {
        case .kilograms: "kg"
        case .pounds: "lb"
        }
    }

    var fieldLabel: String {
        switch self {
        case .kilograms: "Kilogramos"
        case .pounds: "Libras"
        }
    }

    static func loadPreferred() -> WeightUnit {
        guard let raw = UserDefaults.standard.string(forKey: Keys.weight),
              let unit = WeightUnit(rawValue: raw) else { return .kilograms }
        return unit
    }

    func savePreferred() {
        UserDefaults.standard.set(rawValue, forKey: Keys.weight)
    }

    func format(kg: Double?) -> String {
        guard let kg else { return "" }
        switch self {
        case .kilograms:
            return String(format: "%g", kg)
        case .pounds:
            return String(format: "%.1f", kg / 0.453_592)
        }
    }

    func parseToKg(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let value = Double(trimmed.replacingOccurrences(of: ",", with: ".")) else {
            return nil
        }
        switch self {
        case .kilograms:
            return value
        case .pounds:
            return value * 0.453_592
        }
    }
}

private enum Keys {
    static let height = "rivalo.profile.heightUnit"
    static let weight = "rivalo.profile.weightUnit"
}
