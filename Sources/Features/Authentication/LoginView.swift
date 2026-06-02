import ComposableArchitecture
import SwiftUI

struct LoginView: View {
    @Bindable var store: StoreOf<AuthenticationFeature>

    var body: some View {
        AuthScreenLayout(
            title: "Sign in",
            subtitle: "Welcome back."
        ) {
            VStack(spacing: Theme.Spacing.large) {
                VStack(spacing: Theme.Spacing.medium) {
                    AuthTextField(
                        placeholder: "Email",
                        text: $store.email,
                        keyboard: .emailAddress,
                        textContentType: .emailAddress
                    )
                    AuthSecureField(placeholder: "Password", text: $store.password)
                }

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
            AuthFooterLink(prefix: "New here?", actionTitle: "Create account") {
                store.send(.showRegisterTapped)
            }
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
