import ComposableArchitecture
import SwiftUI

struct RecordView: View {
    @Bindable var store: StoreOf<RecordFeature>

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                IfLetStore(store.scope(state: \.$liveMatch, action: \.liveMatch)) { liveStore in
                    LiveMatchView(store: liveStore)
                } else: {
                    VStack(spacing: Theme.Spacing.xl) {
                        Spacer()

                        VStack(spacing: Theme.Spacing.large) {
                            RecordStartOrb {
                                store.send(.recordTapped)
                            }

                            VStack(spacing: Theme.Spacing.small) {
                                Text("Start match")
                                    .font(Theme.Typography.title(size: 26))
                                    .foregroundStyle(Theme.Colors.textPrimary)

                                Text("Captures live stats on your Apple Watch")
                                    .font(Theme.Typography.body(size: 15))
                                    .foregroundStyle(Theme.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }

                        if let setup = store.lastSetup {
                            lastSetupCard(setup)
                        }

                        Button {
                            store.send(.measureCourtTapped)
                        } label: {
                            Label("Measure court", systemImage: "ruler")
                                .font(Theme.Typography.button(size: 16))
                                .foregroundStyle(Theme.Colors.accent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .overlay {
                                    Capsule()
                                        .strokeBorder(Theme.Colors.accent.opacity(0.5), lineWidth: 1)
                                }
                        }
                        .padding(.bottom, Theme.Spacing.xl)

                        Spacer()
                    }
                    .padding(.horizontal, Theme.Spacing.xl)
                }
            }
            .rivalNavigationChrome(title: store.liveMatch != nil ? "Live Match" : "Record")
            .alert(
                "Record match",
                isPresented: recordAlertPresented,
                actions: {
                    Button("OK", role: .cancel) { store.send(.recordAlertDismissed) }
                },
                message: {
                    if let message = store.recordAlertMessage {
                        Text(message)
                    }
                }
            )
        }
        .tint(Theme.Colors.accent)
        .onAppear { store.send(.onAppear) }
    }

    private var recordAlertPresented: Binding<Bool> {
        Binding(
            get: { store.recordAlertMessage != nil },
            set: { isPresented in
                if !isPresented { store.send(.recordAlertDismissed) }
            }
        )
    }
}

// MARK: - Pulsing start orb

/// Strava-style record control with a breathing orange glow.
private struct RecordStartOrb: View {
    let action: () -> Void

    private let coreSize: CGFloat = 120
    private let pulsePeriod: TimeInterval = 3.4

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            let phase = pulsePhase(at: context.date)

            Button(action: action) {
                ZStack {
                    ambientGlow(phase: phase)
                    pulseRing(phase: phase, lag: 0)
                    pulseRing(phase: phase, lag: 0.5)
                    coreOrb(glow: phase)
                }
                .frame(width: 220, height: 220)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Record match")
        }
    }

    private func pulsePhase(at date: Date) -> CGFloat {
        let t = date.timeIntervalSinceReferenceDate
        return CGFloat((sin(t * 2 * .pi / pulsePeriod) + 1) / 2)
    }

    private func ambientGlow(phase: CGFloat) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Theme.Colors.accentBright.opacity(0.2 + phase * 0.12),
                        Theme.Colors.accent.opacity(0.08 + phase * 0.06),
                        Theme.Colors.accent.opacity(0),
                    ],
                    center: .center,
                    startRadius: coreSize * 0.25,
                    endRadius: coreSize * 0.9
                )
            )
            .frame(width: coreSize * 1.65, height: coreSize * 1.65)
            .scaleEffect(0.97 + phase * 0.04)
            .blur(radius: 12 + phase * 5)
    }

    private func pulseRing(phase: CGFloat, lag: CGFloat) -> some View {
        let shifted = (phase + lag).truncatingRemainder(dividingBy: 1)
        let scale = 1 + shifted * 0.18
        let opacity = (1 - shifted) * 0.25

        return Circle()
            .stroke(Theme.Colors.accentBright.opacity(opacity), lineWidth: 1.5)
            .frame(width: coreSize, height: coreSize)
            .scaleEffect(scale)
            .opacity(opacity)
    }

    private func coreOrb(glow: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Theme.Colors.accent, Theme.Colors.accentBright],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: coreSize, height: coreSize)
                .shadow(color: Theme.Colors.accent.opacity(0.26 + glow * 0.14), radius: 14 + glow * 6)
                .shadow(color: Theme.Colors.accentBright.opacity(0.12 + glow * 0.1), radius: 22 + glow * 6)

            Circle()
                .fill(Color.black)
                .frame(width: 44, height: 44)
        }
        .scaleEffect(1 + glow * 0.01)
    }
}

// MARK: - Last setup

private extension RecordView {
    func lastSetupCard(_ setup: iOSMatchSetup) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LAST MATCH")
                .font(Theme.Typography.statLabel(size: 10))
                .foregroundStyle(Theme.Colors.textSecondary)
                .tracking(0.8)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatLabel)
                        .font(Theme.Typography.body(size: 15))
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text(setup.matchType)
                        .font(Theme.Typography.caption(size: 12))
                        .foregroundStyle(Theme.Colors.textSecondary)

                    if let name = setup.pitchName {
                        Text(name)
                            .font(Theme.Typography.caption(size: 12))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "repeat")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.Colors.accent)
            }
            .padding(12)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Theme.Colors.accent.opacity(0.3), lineWidth: 1)
            }
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    var formatLabel: String {
        guard let setup = store.lastSetup else { return "" }
        var parts: [String] = [setup.mode.capitalized]
        if let comp = setup.competition, !comp.isEmpty {
            parts.append(comp.capitalized)
        }
        return parts.joined(separator: " · ")
    }
}

#Preview {
    RecordView(
        store: Store(initialState: RecordFeature.State()) {
            RecordFeature()
        }
    )
}
