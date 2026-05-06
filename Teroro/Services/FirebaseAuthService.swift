import FirebaseAuth
import SwiftUI

@MainActor
final class FirebaseAuthService: ObservableObject {
    static let shared = FirebaseAuthService()

    @Published private(set) var currentUser: UserData?
    @Published private(set) var isLoggedIn: Bool = false

    private var stateListener: AuthStateDidChangeListenerHandle?

    private init() {
        stateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            Task { @MainActor in
                self.isLoggedIn = (user != nil)
                if let user {
                    self.currentUser = UserData(
                        id: user.uid,
                        email: user.email ?? "",
                        createdAt: user.metadata.creationDate
                    )
                } else {
                    self.currentUser = nil
                }
            }
        }
    }

    deinit {
        if let stateListener {
            Auth.auth().removeStateDidChangeListener(stateListener)
        }
    }

    func createNewUser(email: String, password: String) async throws -> UserData {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let user = result.user
        return UserData(
            id: user.uid,
            email: user.email ?? email,
            createdAt: user.metadata.creationDate
        )
    }

    func signIn(email: String, password: String) async throws -> UserData {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        let user = result.user
        return UserData(
            id: user.uid,
            email: user.email ?? email,
            createdAt: user.metadata.creationDate
        )
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
}
