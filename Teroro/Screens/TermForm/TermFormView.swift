import SwiftUI
import UserNotifications

enum TermFormField: Hashable {
    case title
    case details
}

struct TermFormView<VM: TermFormViewModeling>: View {
    @ObservedObject var viewModel: VM
    let title: String
    let onSave: () -> Void
    let onCancel: () -> Void
    @AppStorage("showNotificationPermissionOverlay") private var showPermissionOverlay = false
    @FocusState private var focusedField: TermFormField?

    var body: some View {
        ScrollView {
            // Використовуємо LazyVStack для кращої продуктивності розмітки
            LazyVStack(spacing: 16) {
                TitleDetailsSection(viewModel: viewModel, focusedField: $focusedField)

                DateTimeSection(date: $viewModel.date)

                ReminderSection(
                    enabled: $viewModel.reminderEnabled,
                    reminderDate: $viewModel.reminderDate,
                    onStatusCheck: checkNotificationStatus
                )

                ActionButtonsSection(
                    isSaveEnabled: viewModel.isSaveEnabled,
                    onSave: {
                        if viewModel.save() {
                            onSave()
                        }
                    },
                    onCancel: onCancel
                )
            }
            .padding(16)
        }
        .background(Color(.secondarySystemGroupedBackground).ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture { hideKeyboard() }
        .safeAreaInset(edge: .bottom) {
            if focusedField != nil {
                HStack {
                    Spacer()
                    Button("Сховати") { hideKeyboard() }
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

// MARK: - Subviews

private struct TitleDetailsSection<VM: TermFormViewModeling>: View {
    @ObservedObject var viewModel: VM
    var focusedField: FocusState<TermFormField?>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Заголовок", text: $viewModel.title)
                .font(.title3.weight(.semibold))
                .frame(height: 54)
                .padding(.horizontal, 16)
                .focused(focusedField, equals: .title)

            Rectangle()
                .fill(Color.secondary.opacity(0.15))
                .frame(height: 1)
                .padding(.horizontal, 16)

            TextField("Деталі", text: $viewModel.details, axis: .vertical)
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

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Дата та час", systemImage: "calendar")
                    .font(.headline)
                Spacer()
            }
            .padding([.horizontal, .top], 16)
            .padding(.bottom, 12)

            HStack {
                Label("Дата", systemImage: "calendar.badge.clock")
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
                Label("Час", systemImage: "clock")
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

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Нагадування")
                        .font(.headline)
                    Text("Повідомити про термін")
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
                    Label("Коли?", systemImage: "bell.fill")
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
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button("Скасувати", action: onCancel)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .foregroundStyle(.primary)

            Button("Зберегти", action: onSave)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(isSaveEnabled ? Color.accentColor : Color.secondary.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .foregroundStyle(.white)
                .disabled(!isSaveEnabled)
        }
    }
}

#Preview {
    NavigationStack {
        TermFormView(
            viewModel: AddTermVM(),
            title: "Новий термін",
            onSave: {},
            onCancel: {}
        )
    }
}
