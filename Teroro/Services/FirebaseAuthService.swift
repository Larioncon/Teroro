import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import GoogleSignIn
import SwiftUI
import UIKit
import AuthenticationServices
import CryptoKit

@MainActor
final class FirebaseAuthService: NSObject, ObservableObject {
    static let shared = FirebaseAuthService()

    @Published private(set) var currentUser: UserData?
    @Published private(set) var isLoggedIn: Bool = false
    @Published private(set) var isResolvingProfile: Bool = true

    private var stateListener: AuthStateDidChangeListenerHandle?
    private var profileListener: ListenerRegistration?
    private let profileService: UserProfileService

    // MARK: - Apple Sign In Properties
    private var currentNonce: String?
    private var appleSignInContinuation: CheckedContinuation<UserData, Error>?

    private override init() {
        self.profileService = .shared
        super.init()

        stateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            Task { @MainActor in
                self.isLoggedIn = (user != nil)
                if let user {
                    self.listenProfile(for: user)
                } else {
                    self.profileListener?.remove()
                    self.profileListener = nil
                    self.currentUser = nil
                    self.isResolvingProfile = false
                }
            }
        }
    }

    deinit {
        if let stateListener {
            Auth.auth().removeStateDidChangeListener(stateListener)
        }
        profileListener?.remove()
    }

    func createNewUser(email: String, password: String) async throws -> UserData {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let user = result.user
            return UserData(
                id: user.uid,
                email: user.email ?? email,
                name: nil,
                avatarURL: nil,
                createdAt: user.metadata.creationDate
            )
        } catch {
            throw UserFacingAuthError(from: error)
        }
    }

    func signIn(email: String, password: String) async throws -> UserData {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            let user = result.user
            return UserData(
                id: user.uid,
                email: user.email ?? email,
                name: nil,
                avatarURL: nil,
                createdAt: user.metadata.creationDate
            )
        } catch {
            throw UserFacingAuthError(from: error)
        }
    }

    func signOut() throws {
        do {
            try Auth.auth().signOut()
        } catch {
            throw UserFacingAuthError(from: error)
        }
    }

    func resetPassword(email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            throw UserFacingAuthError(from: error)
        }
    }

    func isLogin() -> Bool {
        isLoggedIn
    }

    func signInWithGoogle(presenting: UIViewController) async throws -> UserData {
        do {
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                throw NSError(domain: "FirebaseAuthService", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Firebase clientID не знайдено. Перевірте GoogleService-Info.plist."
                ])
            }

            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenting)

            guard let idToken = result.user.idToken?.tokenString else {
                throw NSError(domain: "FirebaseAuthService", code: -2, userInfo: [
                    NSLocalizedDescriptionKey: "Google Sign-In не повернув idToken."
                ])
            }

            let accessToken = result.user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

            let authResult = try await Auth.auth().signIn(with: credential)
            let user = authResult.user
            return UserData(
                id: user.uid,
                email: user.email ?? "",
                name: nil,
                avatarURL: nil,
                createdAt: user.metadata.creationDate
            )
        } catch {
            throw UserFacingAuthError(from: error)
        }
    }

    // MARK: - Apple Sign In

    func signInWithApple() async throws -> UserData {
        return try await withCheckedThrowingContinuation { continuation in
            self.appleSignInContinuation = continuation

            let nonce = randomNonceString()
            self.currentNonce = nonce

            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)

            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap { String(format: "%02x", $0) }.joined()
        return hashString
    }

    private func listenProfile(for authUser: FirebaseAuth.User) {
        profileListener?.remove()
        isResolvingProfile = true

        profileListener = profileService.userDocumentReference(userID: authUser.uid)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self else { return }
                    if let error {
                        self.currentUser = self.profileService.userData(for: authUser, profileData: nil)
                        self.isResolvingProfile = false
                        AppState.shared.showErrorAlert(error.localizedDescription)
                        return
                    }

                    self.currentUser = self.profileService.userData(
                        for: authUser,
                        profileData: snapshot?.data()
                    )
                    self.isResolvingProfile = false
                }
            }
    }
}

extension FirebaseAuthService: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task { @MainActor in
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = currentNonce else {
                    appleSignInContinuation?.resume(throwing: NSError(domain: "FirebaseAuthService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid nonce state."]))
                    return
                }
                guard let appleIDToken = appleIDCredential.identityToken else {
                    appleSignInContinuation?.resume(throwing: NSError(domain: "FirebaseAuthService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch identity token."]))
                    return
                }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    appleSignInContinuation?.resume(throwing: NSError(domain: "FirebaseAuthService", code: -5, userInfo: [NSLocalizedDescriptionKey: "Unable to serialize token string."]))
                    return
                }

                let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                                 rawNonce: nonce,
                                                                 fullName: appleIDCredential.fullName)

                do {
                    let result = try await Auth.auth().signIn(with: credential)
                    let user = result.user
                    let userData = UserData(
                        id: user.uid,
                        email: user.email ?? "",
                        name: nil,
                        avatarURL: nil,
                        createdAt: user.metadata.creationDate
                    )
                    appleSignInContinuation?.resume(returning: userData)
                } catch {
                    appleSignInContinuation?.resume(throwing: UserFacingAuthError(from: error))
                }
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            appleSignInContinuation?.resume(throwing: UserFacingAuthError(from: error))
        }
    }
}

