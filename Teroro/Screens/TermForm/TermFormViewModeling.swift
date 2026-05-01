//
//  TermFormViewModeling.swift
//  Teroro
//
//  Created by Chmil Oleksandr on 3/10/26.
//

import Foundation

@MainActor
protocol TermFormViewModeling: ObservableObject {
    var title: String { get set }
    var details: String { get set }
    var date: Date { get set }
    var reminderEnabled: Bool { get set }
    var reminderDate: Date { get set }
    var isSaveEnabled: Bool { get }

    func save() -> Bool
}
