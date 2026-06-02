import ComposableArchitecture
import SwiftUI

struct AuthenticationView: View {
    @Bindable var store: StoreOf<AuthenticationFeature>

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.large) {
                Spacer()

                VStack(spacing: Theme.Spacing.small) {
                    Text("RIVALO")
                        .font(Theme.Typography.logo())
                        .tracking(6)
                        .foregroundStyle(Theme.Colors.accent)
                    Text(store.mode == .signIn ? "Welcome back" : "Create your account")
                        .font(Theme.Typography.body())
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                VStack(spacing: Theme.Spacing.medium) {
                    field(
                        "Email",
                        text: $store.email,
                        keyboard: .emailAddress,
                        textContentType: .emailAddress
                    )
                    secureField("Password", text: $store.password)

                    if let message = store.errorMessage {
                        banner(message, color: Theme.Colors.negative)
                    }
                    if let message = store.infoMessage {
                        banner(message, color: Theme.Colors.accent)
                    }

                    Button {
                        store.send(.submitTapped)
                    } label: {
                        ZStack {
                            if store.isSubmitting {
                                ProgressView().tint(.black)
                            } else {
                                Text(store.mode == .signIn ? "Sign in" : "Create account")
                                    .font(Theme.Typography.button())
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(store.canSubmit ? Theme.Colors.accent : Theme.Colors.surface)
                        .foregroundStyle(store.canSubmit ? Color.black : Theme.Colors.textSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                    }
                    .disabled(!store.canSubmit)
                }

                Button {
                    store.send(.toggleModeTapped)
                } label: {
                    Text(store.mode == .signIn
                         ? "Don't have an account? Sign up"
                         : "Already have an account? Sign in")
                        .font(Theme.Typography.caption())
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                Spacer()
            }
            .padding(Theme.Spacing.large)
        }
        .foregroundStyle(Theme.Colors.textPrimary)
    }

    private func field(
        _ placeholder: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil
    ) -> some View {
        TextField("", text: text, prompt: Text(placeholder).foregroundStyle(Theme.Colors.textSecondary))
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(keyboard)
            .textContentType(textContentType)
            .padding()
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .foregroundStyle(Theme.Colors.textPrimary)
    }

    private func secureField(_ placeholder: String, text: Binding<String>) -> some View {
        SecureField("", text: text, prompt: Text(placeholder).foregroundStyle(Theme.Colors.textSecondary))
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding()
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .foregroundStyle(Theme.Colors.textPrimary)
    }

    private func banner(_ message: String, color: Color) -> some View {
        Text(message)
            .font(Theme.Typography.caption())
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    AuthenticationView(
        store: Store(initialState: AuthenticationFeature.State()) {
            AuthenticationFeature()
        }
    )
}
