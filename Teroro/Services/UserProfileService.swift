import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UIKit

final class UserProfileService {
    static let shared = UserProfileService()

    private let db: Firestore
    private let storage: Storage

    init(db: Firestore = Firestore.firestore(), storage: Storage = Storage.storage()) {
        self.db = db
        self.storage = storage
    }

    func userDocumentReference(userID: String) -> DocumentReference {
        db.collection("users").document(userID)
    }

    func userData(for authUser: FirebaseAuth.User, profileData: [String: Any]?) -> UserData {
        let user = UserData(
            id: authUser.uid,
            email: profileData?["email"] as? String ?? authUser.email ?? "",
            name: profileData?["name"] as? String ?? UserProfileLocalCache.cachedName(for: authUser.uid),
            avatarURL: profileData?["avatarURL"] as? String ?? UserProfileLocalCache.cachedAvatarURL(for: authUser.uid),
            createdAt: authUser.metadata.creationDate
        )

        UserProfileLocalCache.store(user: user)
        return user
    }

    func saveProfile(name: String, avatar: SetupAvatarChoice) async throws -> UserData {
        guard let authUser = Auth.auth().currentUser else {
            throw UserProfileError.missingUser
        }

        let avatarURL: String
        switch avatar {
        case .systemDefault:
            avatarURL = "ava0"
        case .image(let image):
            avatarURL = try await uploadAvatar(image, userID: authUser.uid)
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = authUser.email ?? ""
        let data: [String: Any] = [
            "id": authUser.uid,
            "email": email,
            "name": trimmedName,
            "avatarURL": avatarURL,
            "updatedAt": FieldValue.serverTimestamp(),
            "createdAt": FieldValue.serverTimestamp()
        ]

        try await setData(data, for: userDocumentReference(userID: authUser.uid), merge: true)

        let user = UserData(
            id: authUser.uid,
            email: email,
            name: trimmedName,
            avatarURL: avatarURL,
            createdAt: authUser.metadata.creationDate
        )
        UserProfileLocalCache.store(user: user)
        return user
    }

    func updateAvatar(_ avatar: SetupAvatarChoice) async throws -> UserData {
        guard let authUser = Auth.auth().currentUser else {
            throw UserProfileError.missingUser
        }

        let avatarURL: String
        switch avatar {
        case .systemDefault:
            avatarURL = "ava0"
        case .image(let image):
            avatarURL = try await uploadAvatar(image, userID: authUser.uid)
        }

        let data: [String: Any] = [
            "avatarURL": avatarURL,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        try await setData(data, for: userDocumentReference(userID: authUser.uid), merge: true)

        let user = UserData(
            id: authUser.uid,
            email: authUser.email ?? "",
            name: UserProfileLocalCache.cachedName(for: authUser.uid),
            avatarURL: avatarURL,
            createdAt: authUser.metadata.creationDate
        )
        UserProfileLocalCache.store(user: user)
        return user
    }

    private func uploadAvatar(_ image: UIImage, userID: String) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.82) else {
            throw UserProfileError.invalidImage
        }

        let reference = storage.reference()
            .child("avatars")
            .child(userID)
            .child("profile.jpg")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await putData(data, metadata: metadata, reference: reference)
        return try await downloadURL(for: reference).absoluteString
    }

    private func setData(_ data: [String: Any], for reference: DocumentReference, merge: Bool) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            reference.setData(data, merge: merge) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func putData(_ data: Data, metadata: StorageMetadata, reference: StorageReference) async throws -> StorageMetadata {
        try await withCheckedThrowingContinuation { continuation in
            reference.putData(data, metadata: metadata) { metadata, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let metadata {
                    continuation.resume(returning: metadata)
                } else {
                    continuation.resume(throwing: UserProfileError.uploadFailed)
                }
            }
        }
    }

    private func downloadURL(for reference: StorageReference) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            reference.downloadURL { url, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: UserProfileError.uploadFailed)
                }
            }
        }
    }
}

enum SetupAvatarChoice {
    case systemDefault
    case image(UIImage)
}

enum UserProfileError: LocalizedError {
    case missingUser
    case invalidImage
    case uploadFailed

    var errorDescription: String? {
        switch self {
        case .missingUser:
            return "Користувач не авторизований."
        case .invalidImage:
            return "Не вдалося підготувати фото профілю."
        case .uploadFailed:
            return "Не вдалося завантажити фото профілю."
        }
    }
}
