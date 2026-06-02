import ComposableArchitecture
import SwiftUI

struct RegisterView: View {
    @Bindable var store: StoreOf<AuthenticationFeature>

    var body: some View {
        AuthScreenLayout(
            title: "Create account",
            subtitle: "Join Rivalo and track your game."
        ) {
            VStack(spacing: Theme.Spacing.medium) {
                AuthTextField(
                    label: "Email",
                    text: $store.email,
                    keyboard: .emailAddress,
                    textContentType: .emailAddress
                )
                AuthSecureField(label: "Password", text: $store.password)

                Text("At least 6 characters")
                    .font(Theme.Typography.statLabel())
                    .foregroundStyle(Theme.Colors.textSecondary)

                messages

                AuthPrimaryButton(
                    title: "Create account",
                    isEnabled: store.canSubmitRegister,
                    isLoading: store.isSubmitting
                ) {
                    store.send(.submitTapped)
                }
            }
        } footer: {
            HStack(spacing: 4) {
                Text("Already have an account?")
                    .font(Theme.Typography.caption())
                    .foregroundStyle(Theme.Colors.textSecondary)
                AuthLinkButton(title: "Sign in") {
                    store.send(.showLoginTapped)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, Theme.Spacing.small)
        }
    }

    @ViewBuilder
    private var messages: some View {
        if let message = store.errorMessage {
            AuthInlineMessage(text: message, kind: .error)
        }
        if let message = store.infoMessage {
            AuthInlineMessage(text: message, kind: .info)
        }
    }
}
