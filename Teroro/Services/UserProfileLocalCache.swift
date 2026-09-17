import Foundation

struct UserProfileLocalCache {
    private static let defaults = UserDefaults.standard

    static func cachedName(for userID: String) -> String? {
        defaults.string(forKey: key("name", userID: userID))
    }

    static func cachedAvatarURL(for userID: String) -> String? {
        defaults.string(forKey: key("avatarURL", userID: userID))
    }

    static func store(user: UserData) {
        if let name = user.name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            defaults.set(name, forKey: key("name", userID: user.id))
        }

        if let avatarURL = user.avatarURL, !avatarURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            defaults.set(avatarURL, forKey: key("avatarURL", userID: user.id))
        }
    }

    static func clear(for userID: String) {
        defaults.removeObject(forKey: key("name", userID: userID))
        defaults.removeObject(forKey: key("avatarURL", userID: userID))
    }

    private static func key(_ field: String, userID: String) -> String {
        "userProfile.\(userID).\(field)"
    }
}
