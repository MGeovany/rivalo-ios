import ComposableArchitecture
import SwiftUI

struct ForgotPasswordView: View {
    @Bindable var store: StoreOf<AuthenticationFeature>

    var body: some View {
        AuthScreenLayout(
            title: "Restablecer contraseña",
            subtitle: "Te enviaremos un enlace por correo para establecer una nueva contraseña."
        ) {
            VStack(spacing: Theme.Spacing.large) {
                AuthTextField(
                    placeholder: "Correo electrónico",
                    text: $store.email,
                    keyboard: .emailAddress,
                    textContentType: .emailAddress
                )

                messages

                AuthPrimaryButton(
                    title: "Enviar enlace",
                    isEnabled: store.canSubmitRecover,
                    isLoading: store.isSubmitting
                ) {
                    store.send(.submitTapped)
                }
            }
        } footer: {
            AuthLinkButton(title: "Volver a iniciar sesión") {
                store.send(.showLoginTapped)
            }
            .frame(maxWidth: .infinity)
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
