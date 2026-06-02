import ComposableArchitecture
import SwiftUI

struct RegisterView: View {
    @Bindable var store: StoreOf<AuthenticationFeature>

    var body: some View {
        AuthScreenLayout(
            title: "Create account",
            subtitle: "Track every match."
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

                AuthHint(text: "At least 6 characters")

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
            AuthFooterLink(prefix: "Already have an account?", actionTitle: "Sign in") {
                store.send(.showLoginTapped)
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
