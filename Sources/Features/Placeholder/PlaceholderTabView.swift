import SwiftUI

/// Placeholder for tabs not yet shipped in production.
struct PlaceholderTabView: View {
    let title: String
    let headline: String
    let message: String
    let systemImage: String

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                VStack(spacing: Theme.Spacing.xl) {
                    Image(systemName: systemImage)
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(Theme.Colors.accent)

                    VStack(spacing: Theme.Spacing.small) {
                        Text(headline)
                            .font(Theme.Typography.title(size: 24))
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .multilineTextAlignment(.center)

                        Text(message)
                            .font(Theme.Typography.body(size: 15))
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                    }
                }
                .padding(.horizontal, Theme.Spacing.xl)
            }
            .rivalNavigationChrome(title: title)
        }
        .tint(Theme.Colors.accent)
        .foregroundStyle(Theme.Colors.textPrimary)
    }
}

#Preview {
    PlaceholderTabView(
        title: "Plan",
        headline: "Training plans",
        message: "Structured plans for your next match are on the way.",
        systemImage: "calendar"
    )
}
