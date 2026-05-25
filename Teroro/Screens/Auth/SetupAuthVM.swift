import SwiftUI
import UIKit

@MainActor
final class SetupAuthVM: ObservableObject {
    @Published var name: String = ""
    @Published var selectedImage: UIImage?
    @Published var selectedAvatar: SetupAvatarChoice = .systemDefault
    @Published var isLoading: Bool = false
    @Published var alertMessage: String?
    @Published private(set) var didCompleteSetup = false

    private let profileService: UserProfileService
    private let authService: FirebaseAuthService
    private let avatarCache: UserAvatarCache

    init(
        profileService: UserProfileService = .shared,
        authService: FirebaseAuthService? = nil,
        avatarCache: UserAvatarCache? = nil
    ) {
        self.profileService = profileService
        self.authService = authService ?? .shared
        self.avatarCache = avatarCache ?? .shared
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    func selectDefaultAvatar() {
        selectedImage = nil
        selectedAvatar = .systemDefault
    }

    func selectImage(_ image: UIImage) {
        selectedImage = image
        selectedAvatar = .image(image)
    }

    func saveProfile() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            alertMessage = "Введіть ім'я."
            return
        }

        isLoading = true
        alertMessage = nil

        Task {
            do {
                let user = try await profileService.saveProfile(name: trimmedName, avatar: selectedAvatar)
                if case .image(let image) = selectedAvatar {
                    avatarCache.store(image, for: user.avatarURL)
                }
                didCompleteSetup = true
            } catch {
                alertMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func signOutIfIncomplete() {
        guard !didCompleteSetup else { return }

        do {
            try authService.signOut()
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}
