import SwiftUI

/// Cold-start splash while the session restores.
struct SplashView: View {
    @State private var appeared = false

    private let logoHeight: CGFloat = 26
    private let pulsePeriod: TimeInterval = 2.8

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            RadialGradient(
                colors: [
                    Theme.Colors.accent.opacity(0.07),
                    Theme.Colors.background.opacity(0),
                ],
                center: .center,
                startRadius: 20,
                endRadius: 280
            )
            .ignoresSafeArea()
            .opacity(appeared ? 1 : 0)

            VStack(spacing: Theme.Spacing.large) {
                logoMark
                statusStack
            }
            .offset(y: appeared ? 0 : 8)
        }
        .onAppear {
            withAnimation(.spring(response: 0.62, dampingFraction: 0.84)) {
                appeared = true
            }
        }
    }

    private var logoMark: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            let phase = pulsePhase(at: context.date)

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Theme.Colors.accentBright.opacity(0.14 + phase * 0.1),
                                Theme.Colors.accent.opacity(0.04 + phase * 0.04),
                                .clear,
                            ],
                            center: .center,
                            startRadius: 4,
                            endRadius: 52
                        )
                    )
                    .frame(width: 96, height: 96)
                    .scaleEffect(0.94 + phase * 0.08)
                    .blur(radius: 10 + phase * 4)

                BrandLogo(style: .isotipo, height: logoHeight)
                    .shadow(color: Theme.Colors.accent.opacity(0.22 + phase * 0.12), radius: 10, y: 2)
            }
            .frame(height: 88)
            .scaleEffect(appeared ? 1 : 0.9)
            .opacity(appeared ? 1 : 0)
        }
    }

    private var statusStack: some View {
        VStack(spacing: Theme.Spacing.medium) {
            SplashLoadingIndicator()
            CyclingLoadingMessage(interval: .seconds(2.2))
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.45).delay(0.12), value: appeared)
    }

    private func pulsePhase(at date: Date) -> CGFloat {
        let t = date.timeIntervalSinceReferenceDate
        return CGFloat((sin(t * 2 * .pi / pulsePeriod) + 1) / 2)
    }
}

/// Three-dot loader — lighter than a full spinner on splash.
private struct SplashLoadingIndicator: View {
    @State private var activeIndex = 0

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Theme.Colors.accent)
                    .frame(width: 5, height: 5)
                    .opacity(index == activeIndex ? 1 : 0.28)
                    .scaleEffect(index == activeIndex ? 1.15 : 0.9)
                    .animation(.easeInOut(duration: 0.28), value: activeIndex)
            }
        }
        .task { await cycleDots() }
    }

    private func cycleDots() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(380))
            activeIndex = (activeIndex + 1) % 3
        }
    }
}

#Preview("Splash") {
    SplashView()
}
