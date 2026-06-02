import ComposableArchitecture
import SwiftUI

struct LiveMatchView: View {
    @Bindable var store: StoreOf<LiveMatchFeature>

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            timerDisplay

            HStack(spacing: Theme.Spacing.large) {
                statCard(title: "HR", value: "\(store.heartRate)", unit: "bpm")
                statCard(title: "Distance", value: formattedDistance, unit: "m")
            }

            segmentLabel

            controlButtons

            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    private var timerDisplay: some View {
        Text(formattedElapsed)
            .font(.system(size: 56, weight: .bold, design: .monospaced))
            .foregroundStyle(Theme.Colors.textPrimary)
    }

    private var segmentLabel: some View {
        Text(segmentName)
            .font(Theme.Typography.body(size: 14))
            .foregroundStyle(Theme.Colors.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Theme.Colors.surface)
            .cornerRadius(12)
    }

    private var controlButtons: some View {
        HStack(spacing: Theme.Spacing.medium) {
            if store.segment == "firstHalf" {
                controlButton(
                    label: "Pause",
                    systemImage: "pause.fill",
                    action: { store.send(.pauseTapped) }
                )
                controlButton(
                    label: "Half-time",
                    systemImage: "stopwatch",
                    action: { store.send(.halftimeTapped) }
                )
            } else if store.segment == "secondHalf" {
                controlButton(
                    label: "Resume",
                    systemImage: "play.fill",
                    action: { store.send(.resumeTapped) }
                )
            } else if store.segment == "halftimeBreak" {
                controlButton(
                    label: "2nd Half",
                    systemImage: "forward.fill",
                    action: { store.send(.resumeTapped) }
                )
            }

            controlButton(
                label: "End",
                systemImage: "stop.fill",
                role: .destructive,
                action: { store.send(.endTapped) }
            )
        }
    }

    private func controlButton(
        label: String,
        systemImage: String,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(role: role, action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.title2)
                Text(label)
                    .font(Theme.Typography.caption(size: 11))
            }
            .foregroundStyle(role == .destructive ? .red : Theme.Colors.accent)
            .frame(minWidth: 60)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Theme.Colors.surface)
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }

    private func statCard(title: String, value: String, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(Theme.Typography.caption(size: 12))
                .foregroundStyle(Theme.Colors.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(Theme.Typography.title(size: 28))
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text(unit)
                    .font(Theme.Typography.caption(size: 12))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.Colors.surface)
        .cornerRadius(14)
    }

    private var formattedElapsed: String {
        let minutes = store.elapsedS / 60
        let seconds = store.elapsedS % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var formattedDistance: String {
        String(format: "%.0f", store.distanceM)
    }

    private var segmentName: String {
        switch store.segment {
        case "firstHalf": return "1st Half"
        case "halftimeBreak": return "Half-time"
        case "secondHalf": return "2nd Half"
        default: return store.segment
        }
    }
}

#Preview {
    LiveMatchView(
        store: Store(
            initialState: LiveMatchFeature.State(
                elapsedS: 1247,
                heartRate: 152,
                distanceM: 3820,
                segment: "firstHalf"
            )
        ) {
            LiveMatchFeature()
        }
    )
}
