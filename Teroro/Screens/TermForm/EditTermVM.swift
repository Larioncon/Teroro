//
//  EditTermVM.swift
//  Teroro
//
//  Created by Chmil Oleksandr on 3/10/26.
//

import Foundation

@MainActor
final class EditTermVM: ObservableObject, TermFormViewModeling {
    @Published var title: String
    @Published var details: String
    @Published var date: Date
    @Published var reminderEnabled: Bool
    @Published var reminderDate: Date
    @Published private(set) var isLoading: Bool

    private let termID: UUID
    private let repository: TermsRepository
    private var loadedTerm: Term?

    init(termID: UUID, repository: TermsRepository = .shared) {
        self.termID = termID
        self.repository = repository
        self.title = "Завантаження терміну"
        self.details = "Деталі терміну відобразяться тут після завантаження"
        self.date = Date()
        self.reminderEnabled = false
        self.reminderDate = Date()
        self.isLoading = true

        Task {
            await loadTerm()
        }
    }

    var isSaveEnabled: Bool {
        !isLoading && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func save() async -> Bool {
        do {
            var term = loadedTerm ?? Term(id: termID, title: title, details: details, date: date)
            term.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            term.details = details
            term.date = date
            term.reminderDate = reminderEnabled ? reminderDate : nil
            try await repository.updateTerm(term)

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
            loadedTerm = term
            return true
        } catch {
            AppState.shared.showErrorAlert(error.localizedDescription)
            return false
        }
    }

    private func loadTerm() async {
        do {
            guard let term = try await repository.term(id: termID) else {
                isLoading = false
                return
            }
            loadedTerm = term
            title = term.title
            details = term.details
            date = term.date

            if let reminder = term.reminderDate {
                reminderEnabled = true
                reminderDate = reminder
            } else {
                reminderEnabled = false
                reminderDate = Date()
            }
            isLoading = false
        } catch {
            isLoading = false
            AppState.shared.showErrorAlert(error.localizedDescription)
        }
    }
}
