import ComposableArchitecture
import SwiftUI

struct LoginView: View {
    @Bindable var store: StoreOf<AuthenticationFeature>

    var body: some View {
        AuthScreenLayout(
            title: "Sign in",
            subtitle: "Welcome back. Pick up where you left off."
        ) {
            VStack(spacing: Theme.Spacing.medium) {
                AuthTextField(
                    label: "Email",
                    text: $store.email,
                    keyboard: .emailAddress,
                    textContentType: .emailAddress
                )
                AuthSecureField(label: "Password", text: $store.password)

                HStack {
                    Spacer()
                    AuthLinkButton(title: "Forgot password?") {
                        store.send(.showForgotPasswordTapped)
                    }
                }

                messages

                AuthPrimaryButton(
                    title: "Sign in",
                    isEnabled: store.canSubmitLogin,
                    isLoading: store.isSubmitting
                ) {
                    store.send(.submitTapped)
                }
            }
        } footer: {
            HStack(spacing: 4) {
                Text("New here?")
                    .font(Theme.Typography.caption())
                    .foregroundStyle(Theme.Colors.textSecondary)
                AuthLinkButton(title: "Create account") {
                    store.send(.showRegisterTapped)
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
