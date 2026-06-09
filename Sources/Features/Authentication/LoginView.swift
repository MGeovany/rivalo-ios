import ComposableArchitecture
import SwiftUI

struct LoginView: View {
    @Bindable var store: StoreOf<AuthenticationFeature>

    var body: some View {
        AuthScreenLayout(
            title: "Iniciar sesión",
            subtitle: "Bienvenido de nuevo."
        ) {
            VStack(spacing: Theme.Spacing.large) {
                VStack(spacing: Theme.Spacing.medium) {
                    AuthTextField(
                        placeholder: "Correo electrónico",
                        text: $store.email,
                        keyboard: .emailAddress,
                        textContentType: .emailAddress
                    )
                    AuthSecureField(placeholder: "Contraseña", text: $store.password)
                }

                HStack {
                    Spacer()
                    AuthLinkButton(title: "¿Olvidaste tu contraseña?") {
                        store.send(.showForgotPasswordTapped)
                    }
                }

                messages

                AuthPrimaryButton(
                    title: "Iniciar sesión",
                    isEnabled: store.canSubmitLogin,
                    isLoading: store.isSubmitting
                ) {
                    store.send(.submitTapped)
                }
            }
        } footer: {
            AuthFooterLink(prefix: "¿Nuevo aquí?", actionTitle: "Crear cuenta") {
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
