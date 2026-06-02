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
    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.large) {
                BrandLogo(style: .isotipo, height: 88)
                ProgressView()
                    .tint(Theme.Colors.accent)
            }
        }
    }
}
