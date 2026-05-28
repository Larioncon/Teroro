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

    func submit() {
        alertMessage = nil
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            alertMessage = "Введіть email."
            return
        }
        guard password.count >= 6 else {
            alertMessage = "Пароль має містити щонайменше 6 символів."
            return
        }
        if mode == .signUp, password != confirmPassword {
            alertMessage = "Паролі не співпадають."
            return
        }

        isLoading = true
        Task {
            do {
                switch mode {
                case .signUp:
                    _ = try await auth.createNewUser(email: trimmedEmail, password: password)
                case .signIn:
                    _ = try await auth.signIn(email: trimmedEmail, password: password)
                }
            } catch {
                alertMessage = UserFacingAuthError(from: error).errorDescription
                    ?? UserFacingAuthError.generic.errorDescription
            }
            isLoading = false
        }
    }

    func resetPassword() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            alertMessage = "Введіть email для відновлення паролю."
            return
        }
        isLoading = true
        Task {
            do {
                try await auth.resetPassword(email: trimmedEmail)
                alertMessage = "Лист для відновлення паролю надіслано."
            } catch {
                alertMessage = UserFacingAuthError(from: error).errorDescription
                    ?? UserFacingAuthError.generic.errorDescription
            }
            isLoading = false
        }
    }

    func signOut() {
        do {
            try auth.signOut()
        } catch {
            alertMessage = UserFacingAuthError(from: error).errorDescription
                ?? UserFacingAuthError.generic.errorDescription
        }
    }

    func signInWithGoogle(presenting: UIViewController?) {
        alertMessage = nil
        guard let presenting else {
            alertMessage = "Не вдалося відкрити Google Sign-In."
            return
        }
        isLoading = true
        Task {
            do {
                _ = try await auth.signInWithGoogle(presenting: presenting)
            } catch {
                alertMessage = UserFacingAuthError(from: error).errorDescription
                    ?? UserFacingAuthError.generic.errorDescription
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
                    alertMessage = authError.errorDescription ?? UserFacingAuthError.generic.errorDescription
                }
            }
            isLoading = false
        }
    }
}
