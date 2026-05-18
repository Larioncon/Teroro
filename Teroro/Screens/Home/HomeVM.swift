//
//  HomeVM.swift
//  Teroro
//
//  Created by Chmil Oleksandr on 3/10/26.
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class HomeVM: ObservableObject {
    @Published private(set) var terms: [Term] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoading = true

    private let repository: TermsRepository
    private var termsListener: ListenerRegistration?

    init(repository: TermsRepository = .shared) {
        self.repository = repository
        fetchTerms()
    }

    deinit {
        termsListener?.remove()
    }

    func fetchTerms() {
        termsListener?.remove()
        termsListener = repository.listenTerms { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let terms):
                    self?.isLoading = false
                    self?.terms = terms
                    self?.errorMessage = nil
                    self?.syncReminders(for: terms)
                case .failure(let error):
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                    AppState.shared.showErrorAlert(error.localizedDescription)
                }
            }
        }
    }

    func addTerm(_ term: Term) {
        fetchTerms()
    }

    func deleteTerm(_ term: Term) {
        Task {
            do {
                try await repository.deleteTerm(term)
                await NotificationService.shared.cancelReminder(termID: term.id)
            } catch {
                errorMessage = error.localizedDescription
                AppState.shared.showErrorAlert(error.localizedDescription)
            }
        }
    }

    func upcomingTerms(referenceDate: Date = Date()) -> [Term] {
        terms.filter { $0.date >= referenceDate }
    }

    func pastTerms(referenceDate: Date = Date()) -> [Term] {
        Array(terms.filter { $0.date < referenceDate }.reversed())
    }

    func dateText(for date: Date) -> String {
        Self.dateFormatter.string(from: date)
    }

    func dayText(for date: Date) -> String {
        Self.dayFormatter.string(from: date)
    }

    func yearText(for date: Date) -> String {
        Self.yearFormatter.string(from: date)
    }

    func timeText(for date: Date) -> String {
        Self.timeFormatter.string(from: date)
    }

    var placeholderTerms: [Term] {
        Self.placeholderUpcomingTerms
    }

    var placeholderPastTerms: [Term] {
        Self.placeholderArchivedTerms
    }

    private func syncReminders(for terms: [Term]) {
        Task {
            for term in terms {
                if let reminderDate = term.reminderDate, reminderDate > Date() {
                    await NotificationService.shared.scheduleReminder(
                        termID: term.id,
                        title: term.title,
                        termDate: term.date,
                        reminderDate: reminderDate
                    )
                } else {
                    await NotificationService.shared.cancelReminder(termID: term.id)
                }
            }
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "d MMM"
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    private static let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "yyyy"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private static let placeholderUpcomingTerms: [Term] = [
        Term(title: "Візит до лікаря", details: "Підготувати документи", date: Date().addingTimeInterval(86_400)),
        Term(title: "Подати документи", details: "Перевірити дедлайн", date: Date().addingTimeInterval(172_800)),
        Term(title: "Зустріч", details: "Уточнити адресу", date: Date().addingTimeInterval(259_200))
    ]

    private static let placeholderArchivedTerms: [Term] = [
        Term(title: "Минулі документи", details: "Архівний запис", date: Date().addingTimeInterval(-86_400)),
        Term(title: "Завершений термін", details: "Архівний запис", date: Date().addingTimeInterval(-172_800))
    ]
}
