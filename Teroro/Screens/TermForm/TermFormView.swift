import SwiftUI
import UserNotifications

enum TermFormField: Hashable {
    case title
    case details
}

enum TermFormRoute: Hashable {
    case locationPicker
}

struct TermFormView<VM: TermFormViewModeling>: View {
    @ObservedObject var viewModel: VM
    let title: String
    let onSave: () -> Void
    let onCancel: () -> Void
    @AppStorage("showNotificationPermissionOverlay") private var showPermissionOverlay = false
    @State private var isSaving = false
    @State private var toasts: [Toast] = []
    @FocusState private var focusedField: TermFormField?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TitleDetailsSection(viewModel: viewModel, focusedField: $focusedField)
                    .redacted(reason: viewModel.isLoading ? .placeholder : [])
                    .allowsHitTesting(!viewModel.isLoading)

                DateTimeSection(date: $viewModel.date)
                    .redacted(reason: viewModel.isLoading ? .placeholder : [])
                    .allowsHitTesting(!viewModel.isLoading)

                ReminderSection(
                    enabled: $viewModel.reminderEnabled,
                    reminderDate: $viewModel.reminderDate,
                    onStatusCheck: checkNotificationStatus
                )
                .redacted(reason: viewModel.isLoading ? .placeholder : [])
                .allowsHitTesting(!viewModel.isLoading)

                LocationSection(location: $viewModel.location) { address in
                    UIPasteboard.general.string = address
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation {
                        toasts.insert(.copied(message: address), at: 0)
                    }
                }
                .redacted(reason: viewModel.isLoading ? .placeholder : [])
                .allowsHitTesting(!viewModel.isLoading)

                ActionButtonsSection(
                    isSaveEnabled: viewModel.isSaveEnabled && !viewModel.isLoading && !isSaving,
                    isSaving: isSaving,
                    onSave: {
                        Task {
                            isSaving = true
                            let didSave = await viewModel.save()
                            isSaving = false

                            if didSave {
                                onSave()
                            }
                        }
                    },
                    onCancel: onCancel
                )
            }
            .padding(16)
        }
        .toolbar(.hidden, for: .tabBar)
        .background(Color(.secondarySystemGroupedBackground).ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: TermFormRoute.self) { route in
            switch route {
            case .locationPicker:
                LocationPickerView { selectedLoc in
                    viewModel.location = selectedLoc
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if focusedField != nil {
                HStack {
                    Spacer()
                    Button(LanguageManager.shared.localizedString(forKey: "common.hide")) { hideKeyboard() }
                        .font(.headline)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
                .transition(.opacity)
            }
        }
        .toasts($toasts)
        .task {
            await viewModel.loadTermIfNeeded()
        }
    }

    private func checkNotificationStatus() {
        Task {
            let status = await NotificationService.shared.authorizationStatus()
            switch status {
            case .notDetermined:
                let granted = await NotificationService.shared.requestAuthorization()
                if !granted { showPermissionOverlay = true }
            case .denied:
                showPermissionOverlay = true
            default:
                break
            }
        }
    }
}

private struct LocationSection: View {
    @Binding var location: TermLocation?
    var onCopyAddress: ((String) -> Void)? = nil
    @ObservedObject private var network = NetworkMonitor.shared
    @ObservedObject private var languageManager = LanguageManager.shared

    private var isOnline: Bool {
        network.isConnected
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(languageManager.localizedString(forKey: "term.form.location"))
                            .font(.headline)
                        if !isOnline {
                            Text(languageManager.localizedString(forKey: "term.form.offline"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let location = location {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundStyle(isOnline ? .red : .secondary)
                            Text(location.title ?? location.address ?? languageManager.localizedString(forKey: "term.form.location.selected"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text(isOnline ? languageManager.localizedString(forKey: "term.form.add.meeting.address") : languageManager.localizedString(forKey: "term.form.location.unavailable.offline"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
                .onLongPressGesture(minimumDuration: 0.4) {
                    if let location = location {
                        let text = location.address ?? location.title ?? ""
                        if !text.isEmpty {
                            onCopyAddress?(text)
                        }
                    }
                }
                Spacer()
                
                NavigationLink(value: TermFormRoute.locationPicker) {
                    HStack(spacing: 6) {
                        Image(systemName: "map")
                        Text(location == nil ? languageManager.localizedString(forKey: "common.add") : languageManager.localizedString(forKey: "common.change"))
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isOnline ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.1))
                    .foregroundStyle(isOnline ? Color.accentColor : Color.secondary)
                    .clipShape(Capsule())
                }
                .disabled(!isOnline)
            }
            .padding(16)
        }
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.secondary.opacity(0.15))
                }
        }
        .opacity(isOnline ? 1.0 : 0.6)
        .allowsHitTesting(isOnline)
    }
}

// MARK: - Subviews

private struct TitleDetailsSection<VM: TermFormViewModeling>: View {
    @ObservedObject var viewModel: VM
    var focusedField: FocusState<TermFormField?>.Binding
    @ObservedObject private var languageManager = LanguageManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField(languageManager.localizedString(forKey: "term.form.title.placeholder"), text: $viewModel.title)
                .font(.title3.weight(.semibold))
                .frame(height: 54)
                .padding(.horizontal, 16)
                .focused(focusedField, equals: .title)

            Rectangle()
                .fill(Color.secondary.opacity(0.15))
                .frame(height: 1)
                .padding(.horizontal, 16)

            TextField(languageManager.localizedString(forKey: "term.form.details.placeholder"), text: $viewModel.details, axis: .vertical)
                .lineLimit(5, reservesSpace: true)
                .padding(16)
                .focused(focusedField, equals: .details)
        }
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.secondary.opacity(0.15))
                }
        }
    }
}

private struct DateTimeSection: View {
    @Binding var date: Date
    @ObservedObject private var languageManager = LanguageManager.shared

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label(languageManager.localizedString(forKey: "term.form.date.and.time"), systemImage: "calendar")
                    .font(.headline)
                Spacer()
            }
            .padding([.horizontal, .top], 16)
            .padding(.bottom, 12)

            HStack {
                Label(languageManager.localizedString(forKey: "term.form.date"), systemImage: "calendar.badge.clock")
                    .foregroundStyle(.secondary)
                Spacer()
                DatePicker("", selection: $date, displayedComponents: [.date])
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            Rectangle()
                .fill(Color.secondary.opacity(0.15))
                .frame(height: 1)
                .padding(.horizontal, 16)

            HStack {
                Label(languageManager.localizedString(forKey: "term.form.time"), systemImage: "clock")
                    .foregroundStyle(.secondary)
                Spacer()
                DatePicker("", selection: $date, displayedComponents: [.hourAndMinute])
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.secondary.opacity(0.15))
                }
        }
    }
}

private struct ReminderSection: View {
    @Binding var enabled: Bool
    @Binding var reminderDate: Date
    let onStatusCheck: () -> Void
    @ObservedObject private var languageManager = LanguageManager.shared

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(languageManager.localizedString(forKey: "term.form.reminder"))
                        .font(.headline)
                    Text(languageManager.localizedString(forKey: "term.form.notify.about.term"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: $enabled.animation(.easeInOut(duration: 0.2)))
                    .labelsHidden()
            }
            .padding(16)

            if enabled {
                Rectangle()
                    .fill(Color.secondary.opacity(0.15))
                    .frame(height: 1)
                    .padding(.horizontal, 16)

                HStack {
                    Label(languageManager.localizedString(forKey: "term.form.when"), systemImage: "bell.fill")
                        .foregroundStyle(.secondary)
                    Spacer()
                    DatePicker("", selection: $reminderDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
                .padding(16)
                .transition(.opacity)
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.secondary.opacity(0.15))
                }
        }
        .onChange(of: enabled) { newValue in
            if newValue { onStatusCheck() }
        }
    }
}

private struct ActionButtonsSection: View {
    let isSaveEnabled: Bool
    let isSaving: Bool
    let onSave: () -> Void
    let onCancel: () -> Void
    @ObservedObject private var languageManager = LanguageManager.shared

    var body: some View {
        HStack(spacing: 12) {
            Button(languageManager.localizedString(forKey: "common.cancel"), action: onCancel)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .foregroundStyle(.primary)

            Button(isSaving ? languageManager.localizedString(forKey: "common.saving") : languageManager.localizedString(forKey: "common.save"), action: onSave)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(isSaveEnabled ? Color.accentColor : Color.secondary.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .foregroundStyle(.white)
                .disabled(!isSaveEnabled)
        }
    }
}

// MARK: - Screen Wrappers with @StateObject

struct AddTermView: View {
    @StateObject private var viewModel: AddTermVM
    @ObservedObject private var languageManager = LanguageManager.shared
    let onSave: () -> Void
    let onCancel: () -> Void

    init(onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: AddTermVM())
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        TermFormView(
            viewModel: viewModel,
            title: languageManager.localizedString(forKey: "term.form.new.title"),
            onSave: onSave,
            onCancel: onCancel
        )
    }
}

struct EditTermView: View {
    @StateObject private var viewModel: EditTermVM
    @ObservedObject private var languageManager = LanguageManager.shared
    let onSave: () -> Void
    let onCancel: () -> Void

    init(termID: UUID, onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: EditTermVM(termID: termID))
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        TermFormView(
            viewModel: viewModel,
            title: languageManager.localizedString(forKey: "common.edit"),
            onSave: onSave,
            onCancel: onCancel
        )
    }
}

#Preview {
    NavigationStack {
        TermFormView(
            viewModel: AddTermVM(),
            title: "New Term",
            onSave: {},
            onCancel: {}
        )
    }
}
