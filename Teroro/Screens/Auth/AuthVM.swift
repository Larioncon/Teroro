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

    var primaryButtonTitle: LocalizedStringKey {
        switch mode {
        case .signUp: return "auth.primary.create_account"
        case .signIn: return "auth.primary.sign_in"
        }
    }

    var togglePrompt: LocalizedStringKey {
        switch mode {
        case .signUp: return "auth.toggle.have_account"
        case .signIn: return "auth.toggle.new_here"
        }
    }

    var toggleActionTitle: LocalizedStringKey {
        switch mode {
        case .signUp: return "auth.toggle.log_in"
        case .signIn: return "auth.toggle.sign_up"
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
                showToast(.error(message: error.errorDescription ?? "auth.error.invalid_credentials".localized), haptic: .error)
                return
            case .success(let valid):
                isLoading = true
                Task {
                    do {
                        _ = try await auth.signIn(email: valid.email, password: valid.password)
                    } catch {
                        let message = UserFacingAuthError(from: error).errorDescription
                            ?? UserFacingAuthError.generic.errorDescription
                        showToast(.error(message: message ?? "auth.error.sign_in_failed".localized), haptic: .error)
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
                showToast(.error(message: error.errorDescription ?? "auth.error.invalid_credentials".localized), haptic: .error)
                return
            case .success(let valid):
                isLoading = true
                Task {
                    do {
                        _ = try await auth.createNewUser(email: valid.email, password: valid.password)
                    } catch {
                        let message = UserFacingAuthError(from: error).errorDescription
                            ?? UserFacingAuthError.generic.errorDescription
                        showToast(.error(message: message ?? "auth.error.sign_up_failed".localized), haptic: .error)
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
            showToast(.error(message: error.errorDescription ?? "auth.error.invalid_email".localized), haptic: .error)
            return
        case .success(let validEmail):
            isLoading = true
            Task {
                do {
                    try await auth.resetPassword(email: validEmail)
                    showToast(.success(message: "auth.password_reset.sent".localized), haptic: .success)
                } catch {
                    let message = UserFacingAuthError(from: error).errorDescription
                        ?? UserFacingAuthError.generic.errorDescription
                    showToast(.error(message: message ?? "auth.password_reset.failed".localized), haptic: .error)
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
            showToast(.error(message: message ?? "auth.sign_out.failed".localized), haptic: .error)
        }
    }

    func signInWithGoogle(presenting: UIViewController?) {
        alertMessage = nil
        guard let presenting else {
            showToast(.error(message: "auth.google.open_failed".localized), haptic: .error)
            return
        }
        isLoading = true
        Task {
            do {
                _ = try await auth.signInWithGoogle(presenting: presenting)
            } catch {
                let message = UserFacingAuthError(from: error).errorDescription
                    ?? UserFacingAuthError.generic.errorDescription
                showToast(.error(message: message ?? "auth.google.sign_in_failed".localized), haptic: .error)
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
                    showToast(.error(message: message ?? "auth.apple.sign_in_failed".localized), haptic: .error)
                }
            }
            isLoading = false
        }
    }
}
