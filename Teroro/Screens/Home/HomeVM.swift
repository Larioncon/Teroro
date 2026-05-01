//
//  HomeVM.swift
//  Teroro
//
//  Created by Chmil Oleksandr on 3/10/26.
//

import Foundation
import CoreData
import Combine

@MainActor
final class HomeVM: ObservableObject {
    @Published private(set) var terms: [Term] = []
    private let container: NSPersistentContainer

    init(container: NSPersistentContainer = PersistenceController.shared.container) {
        self.container = container
        fetchTerms()
    }

    func fetchTerms() {
        container.performBackgroundTask { context in
            let request = NSFetchRequest<TermEntity>(entityName: "TermEntity")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \TermEntity.date, ascending: true)]

            do {
                let entities = try context.fetch(request)
                let mapped = entities.map(Term.init)
                Task { @MainActor in
                    self.terms = mapped
                }
            } catch {
                print("Помилка завантаження Core Data: \(error)")
            }
        }
    }

    func addTerm(_ term: Term) {
        fetchTerms()
    }

    func deleteTerm(_ term: Term) {
        container.performBackgroundTask { context in
            let request = NSFetchRequest<TermEntity>(entityName: "TermEntity")
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "id == %@", term.id as CVarArg)

            do {
                if let entity = try context.fetch(request).first {
                    context.delete(entity)
                    try context.save()
                    Task { @MainActor in
                        await NotificationService.shared.cancelReminder(termID: term.id)
                        self.fetchTerms()
                    }
                }
            } catch {
                print("Помилка видалення: \(error)")
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
}
