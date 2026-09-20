import Combine
import SwiftUI
import UIKit

@MainActor
final class AuthVM: ObservableObject {
    enum Mode: Equatable {
        case signUp
        case signIn
    }

    @Published var mode: Mode = .signUp
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var isLoading: Bool = false
    @Published var alertMessage: String?
    @Published var toast: Toast?
    @Published private(set) var isLoggedIn: Bool = false
    @Published private(set) var isResolvingProfile: Bool = true
    @Published private(set) var currentUser: UserData?

    private let auth: FirebaseAuthService
    private var cancellables: Set<AnyCancellable> = []

    init(auth: FirebaseAuthService? = nil) {
        let auth = auth ?? FirebaseAuthService.shared
        self.auth = auth
        self.isLoggedIn = auth.isLoggedIn

        auth.$isLoggedIn
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.isLoggedIn = value
            }
            .store(in: &cancellables)

        auth.$isResolvingProfile
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.isResolvingProfile = value
            }
            .store(in: &cancellables)

        auth.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.currentUser = user
            }
            .store(in: &cancellables)
    }

    var needsProfileSetup: Bool {
        guard isLoggedIn, !isResolvingProfile else { return false }
        return currentUser?.isProfileComplete != true
    }

    var primaryButtonTitle: String {
        switch mode {
        case .signUp: return "Створити акаунт"
        case .signIn: return "Увійти"
        }
    }

    var togglePrompt: String {
        switch mode {
        case .signUp: return "Have an account?"
        case .signIn: return "New here?"
        }
    }

    var toggleActionTitle: String {
        switch mode {
        case .signUp: return "Log In"
        case .signIn: return "Sign Up"
        }
    }

    func toggleMode() {
        withAnimation(.easeInOut(duration: 0.25)) {
            mode = (mode == .signUp) ? .signIn : .signUp
        }
        alertMessage = nil
    }

    func showToast(_ newToast: Toast, haptic: UINotificationFeedbackGenerator.FeedbackType? = nil) {
        if let haptic {
            UINotificationFeedbackGenerator().notificationOccurred(haptic)
        }
        self.toast = newToast
    }

    func submit() {
        alertMessage = nil

        switch mode {
        case .signIn:
            let validationResult = AuthValidator.validateSignIn(email: email, password: password)
            switch validationResult {
            case .failure(let error):
                showToast(.error(title: "Помилка", message: error.errorDescription ?? "Некоректні дані"), haptic: .error)
                return
            case .success(let valid):
                isLoading = true
                Task {
                    do {
                        _ = try await auth.signIn(email: valid.email, password: valid.password)
                    } catch {
                        let message = UserFacingAuthError(from: error).errorDescription
                            ?? UserFacingAuthError.generic.errorDescription
                        showToast(.error(message: message ?? "Помилка авторизації"), haptic: .error)
                    }
                    isLoading = false
                }
            }

        case .signUp:
            let validationResult = AuthValidator.validateSignUp(
                email: email,
                password: password,
                confirmPassword: confirmPassword
            )
            switch validationResult {
            case .failure(let error):
                showToast(.error(title: "Помилка", message: error.errorDescription ?? "Некоректні дані"), haptic: .error)
                return
            case .success(let valid):
                isLoading = true
                Task {
                    do {
                        _ = try await auth.createNewUser(email: valid.email, password: valid.password)
                    } catch {
                        let message = UserFacingAuthError(from: error).errorDescription
                            ?? UserFacingAuthError.generic.errorDescription
                        showToast(.error(message: message ?? "Помилка реєстрації"), haptic: .error)
                    }
                    isLoading = false
                }
            }
        }
    }

    func resetPassword() {
        let validationResult = AuthValidator.validateResetPassword(email: email)
        switch validationResult {
        case .failure(let error):
            showToast(.error(title: "Помилка", message: error.errorDescription ?? "Некоректний email"), haptic: .error)
            return
        case .success(let validEmail):
            isLoading = true
            Task {
                do {
                    try await auth.resetPassword(email: validEmail)
                    showToast(.success(title: "Успішно", message: "Лист для відновлення паролю надіслано."), haptic: .success)
                } catch {
                    let message = UserFacingAuthError(from: error).errorDescription
                        ?? UserFacingAuthError.generic.errorDescription
                    showToast(.error(message: message ?? "Не вдалося скинути пароль"), haptic: .error)
                }
                isLoading = false
            }
        }
    }


    func signOut() {
        do {
            try auth.signOut()
        } catch {
            let message = UserFacingAuthError(from: error).errorDescription
                ?? UserFacingAuthError.generic.errorDescription
            showToast(.error(message: message ?? "Помилка виходу"), haptic: .error)
        }
    }

    func signInWithGoogle(presenting: UIViewController?) {
        alertMessage = nil
        guard let presenting else {
            showToast(.error(message: "Не вдалося відкрити Google Sign-In."), haptic: .error)
            return
        }
        isLoading = true
        Task {
            do {
                _ = try await auth.signInWithGoogle(presenting: presenting)
            } catch {
                let message = UserFacingAuthError(from: error).errorDescription
                    ?? UserFacingAuthError.generic.errorDescription
                showToast(.error(message: message ?? "Помилка Google Sign-In"), haptic: .error)
            }
            isLoading = false
        }
    }

    func signInWithApple() {
        alertMessage = nil
        isLoading = true
        Task {
            do {
                _ = try await auth.signInWithApple()
            } catch {
                // Ignore cancellation error to avoid showing an alert when the user just closes the sheet.
                let authError = UserFacingAuthError(from: error)
                if authError != .cancelled {
                    let message = authError.errorDescription ?? UserFacingAuthError.generic.errorDescription
                    showToast(.error(message: message ?? "Помилка Apple Sign-In"), haptic: .error)
                }
            }
            isLoading = false
        }
    }
}
