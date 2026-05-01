//
//  HomeView.swift
//  Teroro
//
//  Created by Chmil Oleksandr on 3/10/26.
//

import SwiftUI
import UserNotifications
import UIKit

struct HomeView: View {
    @ObservedObject var viewModel: HomeVM
    let onAddTerm: () -> Void
    let onDeleteTerm: (Term) -> Void
    @Environment(\.openURL) private var openURL
    @AppStorage("showNotificationPermissionOverlay") private var showPermissionOverlay = false
    @AppStorage("dismissedNotificationPermission") private var dismissedPermissionOverlay = false
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @Environment(\.scenePhase) private var scenePhase
    @State private var isShowingPastTerms = false
    @State private var pastToggleRotation: Double = 0

    var body: some View {
        let now = Date()
        let upcoming = viewModel.upcomingTerms(referenceDate: now)
        let past = viewModel.pastTerms(referenceDate: now)
        let isPastToggleDisabled = !isShowingPastTerms && past.isEmpty

        ZStack {
            ZStack {
                TermsList(
                    viewModel: viewModel,
                    terms: upcoming,
                    emptyText: "Немає актуальних термінів",
                    onDeleteTerm: onDeleteTerm
                )
                .opacity(isShowingPastTerms ? 0 : 1)
                .scaleEffect(isShowingPastTerms ? 0.985 : 1)
                .blur(radius: isShowingPastTerms ? 1.4 : 0)
                .allowsHitTesting(!isShowingPastTerms)
                .accessibilityHidden(isShowingPastTerms)

                TermsList(
                    viewModel: viewModel,
                    terms: past,
                    emptyText: "Немає минулих термінів",
                    onDeleteTerm: onDeleteTerm
                )
                .opacity(isShowingPastTerms ? 1 : 0)
                .scaleEffect(isShowingPastTerms ? 1 : 0.985)
                .blur(radius: isShowingPastTerms ? 0 : 1.4)
                .allowsHitTesting(isShowingPastTerms)
                .accessibilityHidden(!isShowingPastTerms)
            }

            if showPermissionOverlay && !dismissedPermissionOverlay {
                NotificationPermissionView(
                    onClose: {
                        dismissedPermissionOverlay = true
                        showPermissionOverlay = false
                    },
                    onOpenSettings: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    }
                )
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                AnimatedNavTitle(isShowingPastTerms: isShowingPastTerms)
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    withAnimation(.easeInOut(duration: 0.28)) {
                        pastToggleRotation += 180
                        isShowingPastTerms.toggle()
                    }
                } label: {
                    PastToggleIcon(
                        rotation: pastToggleRotation,
                        isDisabled: isPastToggleDisabled
                    )
                }
                .disabled(isPastToggleDisabled)
                .accessibilityLabel(isShowingPastTerms ? "Актуальні терміни" : "Минулі терміни")

                Button(action: onAddTerm) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Додати термін")
            }
        }
        .onAppear {
            pastToggleRotation = isShowingPastTerms ? 180 : 0
            Task {
                notificationStatus = await UNUserNotificationCenter.current()
                    .notificationSettings()
                    .authorizationStatus
                if notificationStatus == .denied && !dismissedPermissionOverlay {
                    showPermissionOverlay = true
                } else if notificationStatus == .authorized || notificationStatus == .provisional {
                    showPermissionOverlay = false
                }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            guard newPhase == .active else { return }
            Task {
                notificationStatus = await UNUserNotificationCenter.current()
                    .notificationSettings()
                    .authorizationStatus
                if notificationStatus == .authorized || notificationStatus == .provisional {
                    showPermissionOverlay = false
                } else if notificationStatus == .denied && !dismissedPermissionOverlay {
                    showPermissionOverlay = true
                }
            }
        }
    }
}

private struct AnimatedNavTitle: View {
    let isShowingPastTerms: Bool

    var body: some View {
        ZStack {
            title(text: "Терміни", isVisible: !isShowingPastTerms)
            title(text: "Минулі терміни", isVisible: isShowingPastTerms)
        }
        // Keep the title width stable to avoid "jumping" when the text changes.
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityLabel(isShowingPastTerms ? "Минулі терміни" : "Терміни")
    }

    private func title(text: String, isVisible: Bool) -> some View {
        Text(text)
            .font(.headline)
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.94)
            .blur(radius: isVisible ? 0 : 1.5)
            .offset(y: isVisible ? 0 : -3)
    }
}

private struct PastToggleIcon: View {
    let rotation: Double
    let isDisabled: Bool

    var body: some View {
        let angle = rotation.truncatingRemainder(dividingBy: 360)
        let showingClock = (angle < 90) || (angle > 270)

        return ZStack {
            Image(systemName: "calendar.badge.clock")
                .opacity(showingClock ? 1 : 0)
                .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))

            Image(systemName: "calendar")
                .opacity(showingClock ? 0 : 1)
                .rotation3DEffect(.degrees(rotation + 180), axis: (x: 0, y: 1, z: 0))
        }
        .foregroundStyle(isDisabled ? .secondary : Color.blue)
    }
}

private struct TermsList: View {
    let viewModel: HomeVM
    let terms: [Term]
    let emptyText: String
    let onDeleteTerm: (Term) -> Void

    var body: some View {
        List {
            Section {
                if terms.isEmpty {
                    Text(emptyText)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(terms) { term in
                        TermRow(viewModel: viewModel, term: term)
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
        }
        .listStyle(.insetGrouped)
    }
}

private struct TermRow: View {
    let viewModel: HomeVM
    let term: Term

    var body: some View {
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
    }
}

#Preview {
    NavigationStack {
        HomeView(
            viewModel: HomeVM(container: PersistenceController.shared.container),
            onAddTerm: {},
            onDeleteTerm: { _ in }
        )
    }
}
