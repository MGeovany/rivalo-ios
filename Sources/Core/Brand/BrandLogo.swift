import SwiftUI

/// Brand mark from the asset catalog (wordmark or isotipo).
struct BrandLogo: View {
    enum Style {
        case wordmark
        case isotipo
    }

    var style: Style = .wordmark
    var height: CGFloat = 36

    var body: some View {
        Image(style == .wordmark ? "Wordmark" : "Isotipo")
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .accessibilityLabel("Rivalo")
    }
}

/// Shown while the app restores the session on cold start.
struct SplashView: View {
    private static let messages = [
        "Lacing up…",
        "Warming up…",
        "Checking the pitch…",
        "Finding your boots…",
        "Rolling out the ball…",
        "Reading the match sheet…",
        "Almost kickoff…",
        "Arguing about offside…",
        "Bribing the ref with oranges…",
        "Pretending we meant that pass…",
        "Calculating excuses for being late…",
        "Inflating the stat sheet (just a little)…",
        "Hiding the extra slide tackle…",
        "Convincing the captain you're fit…",
        "Scouting yourself on YouTube…",
        "Dodging the group chat warm-up…",
        "Blaming the boots (again)…",
        "Timing the water break perfectly…",
        "Checking if it's actually raining…",
        "Ghosting the pre-match jog…",
        "Polishing the golden boot fantasy…",
        "Running late but sprinting now…",
        "Decoding the coach's hand signals…",
        "Finding where you parked last week…",
        "Replaying that one good touch…",
        "Converting effort into bragging rights…",
        "Fact-checking your top speed…",
        "Downloading pitch-side gossip…",
        "Measuring the touchline tan…",
        "Negotiating parking at the pitch…",
        "Syncing your Sunday league aura…",
        "Asking the keeper for a clean sheet…",
        "Counting steps to the penalty spot…",
        "Reviewing footage no one asked for…",
        "Stretching one hamstring at a time…",
    ]

    @State private var messageIndex = Int.random(in: 0..<messages.count)

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.xl) {
                BrandLogo(style: .isotipo, height: 48)

                VStack(spacing: Theme.Spacing.medium) {
                    ProgressView()
                        .tint(Theme.Colors.accent)
                        .scaleEffect(0.95)

                    Text(Self.messages[messageIndex])
                        .font(Theme.Typography.caption(size: 14))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .contentTransition(.opacity)
                        .animation(.easeInOut(duration: 0.35), value: messageIndex)
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
        }
        .task { await cycleMessages() }
    }

    private func cycleMessages() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(2))
            messageIndex = (messageIndex + 1) % Self.messages.count
        }
    }
}

#Preview("Splash") {
    SplashView()
}
