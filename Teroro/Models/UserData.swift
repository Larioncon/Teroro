import Foundation

struct UserData: Identifiable, Hashable {
    let id: String
    let email: String
    let createdAt: Date?
}

