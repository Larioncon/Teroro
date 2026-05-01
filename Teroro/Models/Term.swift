import Foundation
import CoreData

struct Term: Identifiable, Hashable {
    let id: UUID
    var title: String
    var details: String
    var date: Date
    var reminderDate: Date?

    init(from entity: TermEntity) {
        self.id = entity.id ?? UUID()
        self.title = entity.title ?? ""
        self.details = entity.details ?? ""
        self.date = entity.date ?? Date()
        self.reminderDate = entity.reminderDate
    }

    init(id: UUID = UUID(), title: String, details: String, date: Date, reminderDate: Date? = nil) {
        self.id = id
        self.title = title
        self.details = details
        self.date = date
        self.reminderDate = reminderDate
    }
}
