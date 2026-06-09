import ComposableArchitecture
import SwiftUI

struct RegisterView: View {
    @Bindable var store: StoreOf<AuthenticationFeature>

    var body: some View {
        AuthScreenLayout(
            title: "Crear cuenta",
            subtitle: "Registra cada partido."
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

                AuthHint(text: "Al menos 6 caracteres")

                messages

                AuthPrimaryButton(
                    title: "Crear cuenta",
                    isEnabled: store.canSubmitRegister,
                    isLoading: store.isSubmitting
                ) {
                    store.send(.submitTapped)
                }
            }
        } footer: {
            AuthFooterLink(prefix: "¿Ya tienes cuenta?", actionTitle: "Iniciar sesión") {
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
