import ComposableArchitecture
import SwiftUI

struct AuthenticationView: View {
    @Bindable var store: StoreOf<AuthenticationFeature>

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            Group {
                switch store.screen {
                case .login:
                    LoginView(store: store)
                case .register:
                    RegisterView(store: store)
                case .forgotPassword:
                    ForgotPasswordView(store: store)
                }
            }
            .animation(.easeInOut(duration: 0.22), value: store.screen)
        }
        .foregroundStyle(Theme.Colors.textPrimary)
    }
}

#Preview("Login") {
    AuthenticationView(
        store: Store(initialState: AuthenticationFeature.State(screen: .login)) {
            AuthenticationFeature()
        }
    )
}

#Preview("Register") {
    AuthenticationView(
        store: Store(initialState: AuthenticationFeature.State(screen: .register)) {
            AuthenticationFeature()
        }
    )
}

#Preview("Forgot") {
    AuthenticationView(
        store: Store(initialState: AuthenticationFeature.State(screen: .forgotPassword)) {
            AuthenticationFeature()
        }
    )
}
