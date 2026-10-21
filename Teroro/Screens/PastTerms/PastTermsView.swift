//
//  PastTermsView.swift
//  Teroro
//
//  Created by Chmil Oleksandr on 3/15/26.
//

import SwiftUI

struct PastTermsView: View {
    @ObservedObject var viewModel: HomeVM
    @ObservedObject private var languageManager = LanguageManager.shared
    let onDeleteTerm: (Term) -> Void

    var body: some View {
        let terms = viewModel.isLoading ? viewModel.placeholderPastTerms : viewModel.pastTerms()

        List {
            Section {
                if terms.isEmpty && !viewModel.isLoading {
                    Text(languageManager.localizedString(forKey: "home_no_past_terms"))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(terms) { term in
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
                        .redacted(reason: viewModel.isLoading ? .placeholder : [])
                        .allowsHitTesting(!viewModel.isLoading)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                onDeleteTerm(term)
                            } label: {
                                Label(languageManager.localizedString(forKey: "common_delete"), systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(languageManager.localizedString(forKey: "home_past_terms"))
    }
}

#Preview {
    NavigationStack {
        PastTermsView(viewModel: HomeVM(), onDeleteTerm: { _ in })
    }
}
