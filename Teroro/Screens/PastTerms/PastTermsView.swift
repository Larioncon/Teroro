//
//  PastTermsView.swift
//  Teroro
//
//  Created by Chmil Oleksandr on 3/15/26.
//

import SwiftUI

struct PastTermsView: View {
    @ObservedObject var viewModel: HomeVM
    let onDeleteTerm: (Term) -> Void

    var body: some View {
        List {
            Section {
                ForEach(viewModel.pastTerms()) { term in
                    NavigationLink(value: AppRoute.editTerm(term.id)) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(term.title)
                                .font(.headline)
                                .foregroundStyle(.primary)

                            HStack(spacing: 8) {
                                Text(viewModel.dateText(for: term.date))
                                Text(viewModel.dayText(for: term.date))
                                Text(viewModel.yearText(for: term.date))
                                Text(viewModel.timeText(for: term.date))
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            onDeleteTerm(term)
                        } label: {
                            Label("Видалити", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Минулі терміни")
    }
}

#Preview {
    NavigationStack {
        PastTermsView(viewModel: HomeVM(container: PersistenceController.shared.container), onDeleteTerm: { _ in })
    }
}
