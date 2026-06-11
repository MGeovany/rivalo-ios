import ComposableArchitecture
import SwiftUI

struct LiveMatchView: View {
    @Bindable var store: StoreOf<LiveMatchFeature>

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            timerDisplay

            HStack(spacing: Theme.Spacing.large) {
                statCard(title: "FC", value: "\(store.heartRate)", unit: "bpm")
                statCard(title: "Distancia", value: formattedDistance, unit: "m")
            }

            segmentLabel

            controlButtons

            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: store.segment)
    }

    private var timerDisplay: some View {
        Text(formattedElapsed)
            .font(.system(size: 56, weight: .bold, design: .monospaced))
            .foregroundStyle(Theme.Colors.textPrimary)
            .contentTransition(.numericText(countsDown: false))
            .animation(.snappy(duration: 0.25), value: store.elapsedS)
    }

    private var segmentLabel: some View {
        Text(segmentName)
            .font(Theme.Typography.body(size: 14))
            .foregroundStyle(Theme.Colors.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Theme.Colors.surface)
            .cornerRadius(12)
            .id(store.segment)
            .transition(.opacity.combined(with: .scale(scale: 0.92)))
    }

    private var controlButtons: some View {
        HStack(spacing: Theme.Spacing.medium) {
            if store.segment == "firstHalf" {
                controlButton(
                    label: "Pausa",
                    systemImage: "pause.fill",
                    action: {
                        Feedback.tap()
                        store.send(.pauseTapped)
                    }
                )
                controlButton(
                    label: "Descanso",
                    systemImage: "stopwatch",
                    action: {
                        Feedback.press()
                        store.send(.halftimeTapped)
                    }
                )
            } else if store.segment == "secondHalf" {
                controlButton(
                    label: "Reanudar",
                    systemImage: "play.fill",
                    action: {
                        Feedback.tap()
                        store.send(.resumeTapped)
                    }
                )
            } else if store.segment == "halftimeBreak" {
                controlButton(
                    label: "2do Tiempo",
                    systemImage: "forward.fill",
                    action: {
                        Feedback.press()
                        store.send(.resumeTapped)
                    }
                )
            }

            controlButton(
                label: "Finalizar",
                systemImage: "stop.fill",
                role: .destructive,
                action: {
                    Feedback.matchEnd()
                    store.send(.endTapped)
                }
            )
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: store.segment)
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
        case "firstHalf": return "1er Tiempo"
        case "halftimeBreak": return "Descanso"
        case "secondHalf": return "2do Tiempo"
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
