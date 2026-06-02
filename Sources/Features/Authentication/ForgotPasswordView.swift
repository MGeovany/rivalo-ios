import ComposableArchitecture
import SwiftUI

struct ForgotPasswordView: View {
    @Bindable var store: StoreOf<AuthenticationFeature>

    var body: some View {
        AuthScreenLayout(
            title: "Reset password",
            subtitle: "Enter your email and we will send you a link to choose a new password."
        ) {
            VStack(spacing: Theme.Spacing.medium) {
                AuthTextField(
                    label: "Email",
                    text: $store.email,
                    keyboard: .emailAddress,
                    textContentType: .emailAddress
                )

                messages

                AuthPrimaryButton(
                    title: "Send reset link",
                    isEnabled: store.canSubmitRecover,
                    isLoading: store.isSubmitting
                ) {
                    store.send(.submitTapped)
                }
            }
        } footer: {
            AuthLinkButton(title: "Back to sign in") {
                store.send(.showLoginTapped)
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
