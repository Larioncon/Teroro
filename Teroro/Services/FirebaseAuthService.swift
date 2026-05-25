import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import GoogleSignIn
import SwiftUI
import UIKit

@MainActor
final class FirebaseAuthService: ObservableObject {
    static let shared = FirebaseAuthService()

    @Published private(set) var currentUser: UserData?
    @Published private(set) var isLoggedIn: Bool = false
    @Published private(set) var isResolvingProfile: Bool = true

    private var stateListener: AuthStateDidChangeListenerHandle?
    private var profileListener: ListenerRegistration?
    private let profileService: UserProfileService

    private init(profileService: UserProfileService = .shared) {
        self.profileService = profileService

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
            // Newer GoogleSignIn SDK uses `configuration` + `signIn(withPresenting:)`.
            GIDSignIn.sharedInstance.configuration = config
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenting)

            guard
                let idToken = result.user.idToken?.tokenString
            else {
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
