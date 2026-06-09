import ComposableArchitecture
import Foundation
import PostHog

/// Registration, sign-in, and password recovery (Supabase Auth).
@Reducer
struct AuthenticationFeature {
    @ObservableState
    struct State: Equatable {
        var screen: Screen = .login
        var email = ""
        var password = ""
        var isSubmitting = false
        var errorMessage: String?
        var infoMessage: String?

        enum Screen: Equatable {
            case login
            case register
            case forgotPassword
        }

        var canSubmitLogin: Bool {
            !email.isEmpty && password.count >= 6 && !isSubmitting
        }

        var canSubmitRegister: Bool {
            !email.isEmpty && password.count >= 6 && !isSubmitting
        }

        var canSubmitRecover: Bool {
            !email.isEmpty && !isSubmitting
        }
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case showLoginTapped
        case showRegisterTapped
        case showForgotPasswordTapped
        case submitTapped
        case signInResult(Result<Session, AuthError>)
        case signUpResult(Result<SignUpResult, AuthError>)
        case recoverResult(Result<RecoverSent, AuthError>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case authenticated(Session)
        }
    }

    /// Marker for a successful password-recovery request (no payload).
    enum RecoverSent: Equatable {
        case sent
    }

    @Dependency(\.authClient) var authClient

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                state.errorMessage = nil
                return .none

            case .showLoginTapped:
                state.screen = .login
                clearMessages(&state)
                return .none

            case .showRegisterTapped:
                state.screen = .register
                clearMessages(&state)
                return .none

            case .showForgotPasswordTapped:
                state.screen = .forgotPassword
                clearMessages(&state)
                return .none

            case .submitTapped:
                state.errorMessage = nil
                state.infoMessage = nil
                let email = state.email.trimmingCharacters(in: .whitespacesAndNewlines)

                switch state.screen {
                case .login:
                    guard state.canSubmitLogin else { return .none }
                    state.isSubmitting = true
                    let password = state.password
                    return .run { send in
                        do {
                            let session = try await authClient.signIn(email, password)
                            await send(.signInResult(.success(session)))
                        } catch {
                            await send(.signInResult(.failure(error as? AuthError ?? .invalidResponse)))
                        }
                    }

                case .register:
                    guard state.canSubmitRegister else { return .none }
                    state.isSubmitting = true
                    let password = state.password
                    return .run { send in
                        do {
                            let result = try await authClient.signUp(email, password)
                            await send(.signUpResult(.success(result)))
                        } catch {
                            await send(.signUpResult(.failure(error as? AuthError ?? .invalidResponse)))
                        }
                    }

                case .forgotPassword:
                    guard state.canSubmitRecover else { return .none }
                    state.isSubmitting = true
                    return .run { send in
                        do {
                            try await authClient.recoverPassword(email)
                            await send(.recoverResult(.success(.sent)))
                        } catch {
                            await send(.recoverResult(.failure(error as? AuthError ?? .invalidResponse)))
                        }
                    }
                }

            case let .signInResult(.success(session)):
                state.isSubmitting = false
                let userId = session.userID
                return .merge(
                    .run { _ in
                        PostHogSDK.shared.capture("user_signed_in")
                        PostHogSDK.shared.identify(userId)
                    },
                    .send(.delegate(.authenticated(session)))
                )

            case let .signUpResult(.success(.session(session))):
                state.isSubmitting = false
                let userId = session.userID
                return .merge(
                    .run { _ in
                        PostHogSDK.shared.capture("user_signed_up", properties: [
                            "needs_email_confirmation": false,
                        ])
                        PostHogSDK.shared.identify(userId)
                    },
                    .send(.delegate(.authenticated(session)))
                )

            case .signUpResult(.success(.needsEmailConfirmation)):
                state.isSubmitting = false
                state.screen = .login
                state.password = ""
                state.infoMessage = "Revisa tu correo para confirmar tu cuenta y luego inicia sesión."
                return .run { _ in
                    PostHogSDK.shared.capture("user_signed_up", properties: [
                        "needs_email_confirmation": true,
                    ])
                }

            case .recoverResult(.success(.sent)):
                state.isSubmitting = false
                state.infoMessage = "Si existe una cuenta con este correo, recibirás instrucciones para restablecerla."
                return .run { _ in
                    PostHogSDK.shared.capture("password_recovery_requested")
                }

            case let .signInResult(.failure(error)):
                state.isSubmitting = false
                let signInMsg = errorText(error)
                state.errorMessage = signInMsg
                return .run { [error] _ in
                    PostHogAnalytics.authFailed(flow: "sign_in", error: error)
                }

            case let .signUpResult(.failure(error)):
                state.isSubmitting = false
                let signUpMsg = errorText(error)
                state.errorMessage = signUpMsg
                return .run { [error] _ in
                    PostHogAnalytics.authFailed(flow: "sign_up", error: error)
                }

            case let .recoverResult(.failure(error)):
                state.isSubmitting = false
                let recoverMsg = errorText(error)
                state.errorMessage = recoverMsg
                return .run { [error] _ in
                    PostHogAnalytics.authFailed(flow: "password_recovery", error: error)
                }

            case .delegate:
                return .none
            }
        }
    }

    private func clearMessages(_ state: inout State) {
        state.errorMessage = nil
        state.infoMessage = nil
    }

    private func errorText(_ error: AuthError) -> String {
        switch error {
        case let .message(text): return text
        case let .unauthorized(text): return text
        case .invalidResponse: return "Algo salió mal. Inténtalo de nuevo."
        }
    }
}
