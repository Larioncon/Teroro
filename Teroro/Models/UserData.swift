import Foundation

struct UserData: Identifiable, Hashable {
    let id: String
    let email: String
    let name: String?
    let avatarURL: String?
    let createdAt: Date?

    var isProfileComplete: Bool {
        let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let trimmedAvatarURL = avatarURL?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !trimmedName.isEmpty && !trimmedAvatarURL.isEmpty
    }
}
