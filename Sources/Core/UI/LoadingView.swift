import SwiftUI

enum LoadingMessages {
    static let all = [
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
}

/// Rotating status line shown while waiting on the backend.
struct CyclingLoadingMessage: View {
    var interval: Duration = .seconds(2)

    @State private var messageIndex = Int.random(in: 0..<LoadingMessages.all.count)

    var body: some View {
        Text(LoadingMessages.all[messageIndex])
            .font(Theme.Typography.caption(size: 14))
            .foregroundStyle(Theme.Colors.textSecondary)
            .multilineTextAlignment(.center)
            .frame(minHeight: 20)
            .contentTransition(.opacity)
            .animation(.easeInOut(duration: 0.35), value: messageIndex)
            .task { await cycleMessages() }
    }

    private func cycleMessages() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: interval)
            messageIndex = (messageIndex + 1) % LoadingMessages.all.count
        }
    }
}

/// Spinner plus rotating message for network fetches.
struct LoadingView: View {
    enum Style {
        /// Fills available space — use in full-screen or list placeholders.
        case standard
        /// Tight stack for cards, splash, or below buttons.
        case compact
    }

    var style: Style = .standard
    var showsSpinner: Bool = true

    var body: some View {
        Group {
            switch style {
            case .standard:
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .compact:
                content
            }
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    private var content: some View {
        VStack(spacing: Theme.Spacing.medium) {
            if showsSpinner {
                ProgressView()
                    .tint(Theme.Colors.accent)
                    .scaleEffect(0.95)
            }
            CyclingLoadingMessage()
        }
    }
}

#Preview("Loading") {
    ZStack {
        Theme.Colors.background.ignoresSafeArea()
        LoadingView()
    }
}
