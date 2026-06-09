import SwiftUI

// MARK: - Panel chrome

/// Dark card wrapper matching the pitch map reference UI.
struct PitchMapPanel<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PitchMapStyle.panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(PitchMapStyle.panelBorder, lineWidth: 1)
        }
    }
}

enum PitchMapStyle {
    static let panelBackground = Color(red: 28 / 255, green: 29 / 255, blue: 31 / 255)
    static let panelBorder = Color.white.opacity(0.08)
    static let segmentTrack = Color(red: 18 / 255, green: 19 / 255, blue: 21 / 255)
    static let pitchGreenTop = Color(red: 0.10, green: 0.34, blue: 0.14)
    static let pitchGreenBottom = Color(red: 0.06, green: 0.24, blue: 0.09)
    static let pitchLine = Color.white.opacity(0.32)
}

/// Segmented control: HEATMAP | ROUTE | SPRINTS (reference style).
struct PitchSegmentedControl<Item: Hashable & Identifiable>: View where Item: RawRepresentable, Item.RawValue == String {
    @Binding var selection: Item
    let items: [Item]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items) { item in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        selection = item
                    }
                } label: {
                    Text(item.rawValue.uppercased())
                        .font(Theme.Typography.statLabel(size: 10))
                        .tracking(0.8)
                        .foregroundStyle(selection == item ? Color.black : Theme.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selection == item ? Theme.Colors.accent : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(PitchMapStyle.segmentTrack)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .strokeBorder(PitchMapStyle.panelBorder, lineWidth: 1)
        }
    }
}

/// Capsule picker for match period (Full / 1st / 2nd half).
struct PitchPeriodPicker: View {
    @Binding var selection: PitchMatchPeriod

    var body: some View {
        HStack(spacing: Theme.Spacing.small) {
            ForEach(PitchMatchPeriod.allCases) { period in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        selection = period
                    }
                } label: {
                    Text(period.shortLabel)
                        .font(Theme.Typography.caption(size: 12))
                        .foregroundStyle(selection == period ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(selection == period ? Color.white.opacity(0.1) : Color.clear)
                        )
                        .overlay {
                            if selection == period {
                                Capsule()
                                    .strokeBorder(Theme.Colors.accent.opacity(0.45), lineWidth: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
    }
}

struct PitchAttackDirectionView: View {
    var body: some View {
        HStack(spacing: 6) {
            Text("DIRECCIÓN DE ATAQUE")
                .font(Theme.Typography.statLabel(size: 10))
                .foregroundStyle(Theme.Colors.textSecondary)
                .tracking(1)
            Image(systemName: "arrow.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.Colors.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
    }
}

struct PitchHeatmapLegend: View {
    private let rampColors: [Color] = [
        Color(red: 0.12, green: 0.55, blue: 0.28),
        Color(red: 0.55, green: 0.88, blue: 0.22),
        Color(red: 1, green: 0.72, blue: 0.12),
        Color(red: 1, green: 0.42, blue: 0.08),
        Color(red: 0.92, green: 0.12, blue: 0.08),
    ]

    var body: some View {
        VStack(spacing: 8) {
            LinearGradient(colors: rampColors, startPoint: .leading, endPoint: .trailing)
                .frame(height: 5)
                .clipShape(Capsule())

            HStack {
                Text("MENOS ACTIVIDAD")
                Spacer()
                Text("MÁS ACTIVIDAD")
            }
            .font(Theme.Typography.statLabel(size: 9))
            .foregroundStyle(Theme.Colors.textSecondary)
            .tracking(0.6)
        }
        .padding(.top, 4)
    }
}

struct PitchMapInfoCard: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.medium) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.accent)
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.85))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.Typography.button(size: 15))
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text(subtitle)
                    .font(Theme.Typography.caption(size: 13))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.medium)
        .background(Color(red: 22 / 255, green: 23 / 255, blue: 25 / 255))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
        }
    }
}
