//
//  AddTermVM.swift
//  Teroro
//
//  Created by Chmil Oleksandr on 3/10/26.
//

import Foundation

@MainActor
final class AddTermVM: ObservableObject, TermFormViewModeling {
    @Published var title: String = ""
    @Published var details: String = ""
    @Published var date: Date = Date()
    @Published var reminderEnabled: Bool = false
    @Published var reminderDate: Date = Date()

    private let repository: TermsRepository

    init(repository: TermsRepository = .shared) {
        self.repository = repository
    }

    var isSaveEnabled: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isLoading: Bool {
        false
    }

    func save() async -> Bool {
        do {
            let newID = try await repository.createTerm(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                details: details,
                date: date,
                reminderDate: reminderEnabled ? reminderDate : nil
            )

            if reminderEnabled {
                await NotificationService.shared.requestAuthorizationIfNeeded()
                await NotificationService.shared.scheduleReminder(
                    termID: newID,
                    title: title,
                    termDate: date,
                    reminderDate: reminderDate
                )
            }
            return true
        } catch {
            AppState.shared.showErrorAlert(error.localizedDescription)
            return false
        }
    }
}
