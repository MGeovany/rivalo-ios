import ComposableArchitecture
import Foundation

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
        case recoverResult(Result<Void, AuthError>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case authenticated(Session)
        }
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
                            await send(.recoverResult(.success(())))
                        } catch {
                            await send(.recoverResult(.failure(error as? AuthError ?? .invalidResponse)))
                        }
                    }
                }

            case let .signInResult(.success(session)):
                state.isSubmitting = false
                return .send(.delegate(.authenticated(session)))

            case let .signUpResult(.success(.session(session))):
                state.isSubmitting = false
                return .send(.delegate(.authenticated(session)))

            case .signUpResult(.success(.needsEmailConfirmation)):
                state.isSubmitting = false
                state.screen = .login
                state.password = ""
                state.infoMessage = "Check your email to confirm your account, then sign in."
                return .none

            case .recoverResult(.success):
                state.isSubmitting = false
                state.infoMessage = "If an account exists for this email, you will receive reset instructions."
                return .none

            case let .signInResult(.failure(error)),
                 let .signUpResult(.failure(error)),
                 let .recoverResult(.failure(error)):
                state.isSubmitting = false
                state.errorMessage = errorText(error)
                return .none

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
        case .invalidResponse: return "Something went wrong. Please try again."
        }
    }
}
