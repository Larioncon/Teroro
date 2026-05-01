//
//  EditTermVM.swift
//  Teroro
//
//  Created by Chmil Oleksandr on 3/10/26.
//

import Foundation
import CoreData

@MainActor
final class EditTermVM: ObservableObject, TermFormViewModeling {
    @Published var title: String
    @Published var details: String
    @Published var date: Date
    @Published var reminderEnabled: Bool
    @Published var reminderDate: Date

    private let termID: UUID
    private let context: NSManagedObjectContext

    init(termID: UUID, context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.termID = termID
        self.context = context

        let request = NSFetchRequest<TermEntity>(entityName: "TermEntity")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", termID as CVarArg)

        if let entity = try? context.fetch(request).first {
            self.title = entity.title ?? ""
            self.details = entity.details ?? ""
            self.date = entity.date ?? Date()
            if let reminder = entity.reminderDate {
                self.reminderEnabled = true
                self.reminderDate = reminder
            } else {
                self.reminderEnabled = false
                self.reminderDate = Date()
            }
        } else {
            self.title = ""
            self.details = ""
            self.date = Date()
            self.reminderEnabled = false
            self.reminderDate = Date()
        }
    }

    var isSaveEnabled: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func save() -> Bool {
        let request = NSFetchRequest<TermEntity>(entityName: "TermEntity")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", termID as CVarArg)

        do {
            if let entity = try context.fetch(request).first {
                entity.title = title
                entity.details = details
                entity.date = date
                entity.reminderDate = reminderEnabled ? reminderDate : nil
                try context.save()
                Task {
                    if reminderEnabled {
                        await NotificationService.shared.requestAuthorizationIfNeeded()
                        await NotificationService.shared.scheduleReminder(
                            termID: termID,
                            title: title,
                            termDate: date,
                            reminderDate: reminderDate
                        )
                    } else {
                        await NotificationService.shared.cancelReminder(termID: termID)
                    }
                }
                return true
            }
            return false
        } catch {
            print("Помилка збереження: \(error)")
            return false
        }
    }
}
