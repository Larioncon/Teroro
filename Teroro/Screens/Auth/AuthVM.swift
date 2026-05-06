import Combine
import SwiftUI

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

    private let auth: FirebaseAuthService
    private var cancellables: Set<AnyCancellable> = []

    init(auth: FirebaseAuthService = .shared) {
        self.auth = auth
        self.isLoggedIn = auth.isLoggedIn

        auth.$isLoggedIn
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.isLoggedIn = value
            }
            .store(in: &cancellables)
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
                alertMessage = error.localizedDescription
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
                alertMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func signOut() {
        do {
            try auth.signOut()
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}
