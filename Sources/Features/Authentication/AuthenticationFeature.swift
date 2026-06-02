import ComposableArchitecture
import Foundation

/// Registration and sign-in with email and password (Supabase Auth).
@Reducer
struct AuthenticationFeature {
    @ObservableState
    struct State: Equatable {
        var mode: Mode = .signIn
        var email = ""
        var password = ""
        var isSubmitting = false
        var errorMessage: String?
        var infoMessage: String?

        enum Mode: Equatable { case signIn, signUp }

        var canSubmit: Bool {
            !email.isEmpty && password.count >= 6 && !isSubmitting
        }
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case toggleModeTapped
        case submitTapped
        case signInResult(Result<Session, AuthError>)
        case signUpResult(Result<SignUpResult, AuthError>)
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

            case .toggleModeTapped:
                state.mode = state.mode == .signIn ? .signUp : .signIn
                state.errorMessage = nil
                state.infoMessage = nil
                return .none

            case .submitTapped:
                guard state.canSubmit else { return .none }
                state.isSubmitting = true
                state.errorMessage = nil
                state.infoMessage = nil
                let email = state.email
                let password = state.password

                switch state.mode {
                case .signIn:
                    return .run { send in
                        do {
                            let session = try await authClient.signIn(email, password)
                            await send(.signInResult(.success(session)))
                        } catch {
                            await send(.signInResult(.failure(error as? AuthError ?? .invalidResponse)))
                        }
                    }
                case .signUp:
                    return .run { send in
                        do {
                            let result = try await authClient.signUp(email, password)
                            await send(.signUpResult(.success(result)))
                        } catch {
                            await send(.signUpResult(.failure(error as? AuthError ?? .invalidResponse)))
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
                state.mode = .signIn
                state.infoMessage = "Check your email to confirm your account, then sign in."
                return .none

            case let .signInResult(.failure(error)),
                 let .signUpResult(.failure(error)):
                state.isSubmitting = false
                state.errorMessage = errorText(error)
                return .none

            case .delegate:
                return .none
            }
        }
    }

    private func errorText(_ error: AuthError) -> String {
        switch error {
        case let .message(text): return text
        case .invalidResponse: return "Something went wrong. Please try again."
        }
    }
}
