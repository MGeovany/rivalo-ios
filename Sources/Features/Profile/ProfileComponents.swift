import SwiftUI

// MARK: - Hero

struct ProfileAvatarView: View {
    let initials: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Theme.Colors.accent, Theme.Colors.accentBright],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 92, height: 92)

            Circle()
                .fill(Theme.Colors.surface)
                .frame(width: 84, height: 84)

            Text(initials)
                .font(Theme.Typography.title(size: 28))
                .foregroundStyle(Theme.Colors.textPrimary)
        }
        .accessibilityLabel("Avatar de perfil")
    }
}

/// Main football positions for the profile picker.
enum FootballPosition {
    static let main = [
        "Goalkeeper",
        "Centre-back",
        "Full-back",
        "Defender",
        "Defensive midfielder",
        "Central midfielder",
        "Midfielder",
        "Attacking midfielder",
        "Winger",
        "Forward",
        "Striker",
    ]

    static let localized: [String: String] = [
        "Goalkeeper": "Portero",
        "Centre-back": "Defensa central",
        "Full-back": "Lateral",
        "Defender": "Defensa",
        "Defensive midfielder": "Medio defensivo",
        "Central midfielder": "Medio centro",
        "Midfielder": "Mediocampista",
        "Attacking midfielder": "Mediapunta",
        "Winger": "Extremo",
        "Forward": "Delantero",
        "Striker": "Ariete",
    ]

    static func displayName(_ position: String) -> String {
        localized[position] ?? position
    }

    static let unsetLabel = "Seleccionar posición"
}

struct ProfileCountrySelect: View {
    let code: String
    let onChange: (String) -> Void

    private var options: [(code: String, name: String)] {
        var list = FootballCountry.options
        let upper = code.uppercased()
        if !upper.isEmpty, !list.contains(where: { $0.code == upper }) {
            list.append((upper, FootballCountry.name(for: upper)))
        }
        return list.sorted { $0.name < $1.name }
    }

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.medium) {
            VStack(alignment: .leading, spacing: 6) {
                Text("País / nacionalidad")
                    .font(Theme.Typography.caption(size: 12))
                    .foregroundStyle(Theme.Colors.textSecondary)

                Picker("País", selection: selectionBinding) {
                    ForEach(options, id: \.code) { option in
                        Text("\(FootballCountry.flagEmoji(for: option.code))  \(option.name)")
                            .tag(option.code)
                    }
                }
                .pickerStyle(.menu)
                .tint(Theme.Colors.accent)
                .font(Theme.Typography.body(size: 17))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 10)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Theme.Colors.textSecondary.opacity(0.25))
                        .frame(height: 1)
                }
            }
        }
    }

    private var selectionBinding: Binding<String> {
        Binding(
            get: { code },
            set: { onChange($0) }
        )
    }
}

struct ProfilePositionSelect: View {
    @Binding var selection: String

    private var options: [String] {
        var list = [""] + FootballPosition.main
        let trimmed = selection.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty, !list.contains(trimmed) {
            list.append(trimmed)
        }
        return list
    }

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.medium) {
            Image(systemName: "sportscourt.fill")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Theme.Colors.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 6) {
                Text("Posición preferida")
                    .font(Theme.Typography.caption(size: 12))
                    .foregroundStyle(Theme.Colors.textSecondary)

                Picker("Posición preferida", selection: $selection) {
                    ForEach(options, id: \.self) { position in
                        Text(label(for: position)).tag(position)
                    }
                }
                .pickerStyle(.menu)
                .tint(Theme.Colors.accent)
                .font(Theme.Typography.body(size: 17))
                .foregroundStyle(
                    selection.isEmpty ? Theme.Colors.textSecondary : Theme.Colors.textPrimary
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 10)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Theme.Colors.textSecondary.opacity(0.25))
                        .frame(height: 1)
                }
            }
        }
    }

    private func label(for position: String) -> String {
        position.isEmpty ? FootballPosition.unsetLabel : FootballPosition.displayName(position)
    }
}

// MARK: - Sections

struct ProfileSectionCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text(title.uppercased())
                .font(Theme.Typography.statLabel(size: 11))
                .foregroundStyle(Theme.Colors.textSecondary)
                .tracking(1.2)

            content()
        }
        .padding(Theme.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }
}

struct ProfileFieldRow: View {
    let icon: String
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboard: UIKeyboardType = .default
    var textContentType: UITextContentType?

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Theme.Colors.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(Theme.Typography.caption(size: 12))
                    .foregroundStyle(Theme.Colors.textSecondary)

                TextField("", text: $text, prompt: prompt)
                    .keyboardType(keyboard)
                    .textContentType(textContentType)
                    .autocorrectionDisabled()
                    .font(Theme.Typography.body(size: 17))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .padding(.bottom, 10)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(Theme.Colors.textSecondary.opacity(0.25))
                            .frame(height: 1)
                    }
            }
        }
    }

    private var prompt: Text {
        Text(placeholder).foregroundStyle(Theme.Colors.textSecondary.opacity(0.85))
    }
}

struct ProfileMetricField<Unit: Hashable & Identifiable>: View where Unit: CaseIterable {
    let label: String
    @Binding var text: String
    let unit: Unit
    let unitLabel: (Unit) -> String
    let onUnitChange: (Unit) -> Void
    var keyboard: UIKeyboardType = .decimalPad

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            HStack {
                Text(label)
                    .font(Theme.Typography.caption(size: 12))
                    .foregroundStyle(Theme.Colors.textSecondary)

                Spacer()

                Picker("Unidad", selection: unitBinding) {
                    ForEach(Array(Unit.allCases), id: \.self) { option in
                        Text(unitLabel(option)).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .tint(Theme.Colors.accent)
            }

            TextField("—", text: $text)
                .keyboardType(keyboard)
                .font(Theme.Typography.metric(size: 32))
                .foregroundStyle(Theme.Colors.accent)
                .monospacedDigit()
                .multilineTextAlignment(.leading)
                .padding(.bottom, 8)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Theme.Colors.textSecondary.opacity(0.25))
                        .frame(height: 1)
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var unitBinding: Binding<Unit> {
        Binding(
            get: { unit },
            set: { onUnitChange($0) }
        )
    }
}

struct ProfilePrimaryButton: View {
    let title: String
    let isEnabled: Bool
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.medium) {
            Button(action: action) {
                ZStack {
                    if isLoading {
                        ProgressView().tint(.black)
                    } else {
                        Text(title)
                            .font(Theme.Typography.button(size: 17))
                            .foregroundStyle(Color.black.opacity(isEnabled ? 1 : 0.5))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Theme.Colors.accent.opacity(isEnabled ? 1 : 0.35))
                .clipShape(Capsule())
            }
            .disabled(!isEnabled || isLoading)

            if isLoading {
                CyclingLoadingMessage()
            }
        }
    }
}

struct ProfileSignOutButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.small) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Cerrar sesión")
                    .font(Theme.Typography.button(size: 16))
            }
            .foregroundStyle(Theme.Colors.negative)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.medium)
        }
        .buttonStyle(.plain)
    }
}

struct ProfileDeleteAccountButton: View {
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.small) {
                if isLoading {
                    ProgressView().tint(Theme.Colors.negative)
                } else {
                    Image(systemName: "trash")
                    Text("Eliminar cuenta")
                        .font(Theme.Typography.button(size: 16))
                }
            }
            .foregroundStyle(Theme.Colors.negative.opacity(0.7))
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.small)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

// MARK: - Helpers

enum ProfileFormatting {
    static func initials(from name: String) -> String {
        let parts = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ")
            .prefix(2)
        if parts.isEmpty { return "?" }
        return parts.map { String($0.prefix(1)).uppercased() }.joined()
    }

    static func positionAbbreviation(_ position: String?) -> String {
        guard let position else { return "—" }
        switch position.lowercased() {
        case "goalkeeper": return "GK"
        case "centre-back", "center-back": return "CB"
        case "full-back": return "LB"
        case "defender": return "CB"
        case "defensive midfielder": return "CDM"
        case "central midfielder": return "CM"
        case "midfielder": return "CM"
        case "attacking midfielder": return "CAM"
        case "winger": return "LW"
        case "forward": return "CF"
        case "striker": return "ST"
        default:
            let words = position.split(separator: " ")
            if words.count >= 2 {
                return words.prefix(2).map { String($0.prefix(1)).uppercased() }.joined()
            }
            return String(position.prefix(3)).uppercased()
        }
    }
}
