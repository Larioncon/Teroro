//
//  AddTermVM.swift
//  Teroro
//
//  Created by Chmil Oleksandr on 3/10/26.
//

import Foundation
import CoreData

@MainActor
final class AddTermVM: ObservableObject, TermFormViewModeling {
    @Published var title: String = ""
    @Published var details: String = ""
    @Published var date: Date = Date()
    @Published var reminderEnabled: Bool = false
    @Published var reminderDate: Date = Date()

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    var isSaveEnabled: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func save() -> Bool {
        let newEntity = TermEntity(context: context)
        let newID = UUID()
        newEntity.id = newID
        newEntity.title = title
        newEntity.details = details
        newEntity.date = date
        newEntity.reminderDate = reminderEnabled ? reminderDate : nil

        do {
            try context.save()
            if reminderEnabled {
                Task {
                    await NotificationService.shared.requestAuthorizationIfNeeded()
                    await NotificationService.shared.scheduleReminder(
                        termID: newID,
                        title: title,
                        termDate: date,
                        reminderDate: reminderDate
                    )
                }
            }
            return true
        } catch {
            print("Помилка збереження: \(error)")
            return false
        }
    }
}
