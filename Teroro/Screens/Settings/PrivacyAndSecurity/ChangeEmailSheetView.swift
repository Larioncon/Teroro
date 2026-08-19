import SwiftUI

struct ChangeEmailSheetView: View {
    @ObservedObject var viewModel: SettingsVM
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newEmail = ""
    @State private var verificationCode = ""
    @State private var isCodeSent = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Новий Email", text: $newEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .disabled(isCodeSent)

                    SecureField("Поточний пароль", text: $currentPassword)
                        .disabled(isCodeSent)
                } header: {
                    Text("Новий email")
                } footer: {
                    if isCodeSent {
                        Text("Поточний email: \(viewModel.currentUser?.email ?? "—"). Введіть код з листа Firebase, який прийшов на новий email. Якщо лист містить посилання, використайте значення параметра oobCode.")
                    } else {
                        Text("Поточний email: \(viewModel.currentUser?.email ?? "—"). Після підтвердження паролю, надійде лист на новий email для верифікації.")
                    }
                }

                if isCodeSent {
                    Section("Підтвердження") {
                        TextField("Код підтвердження", text: $verificationCode)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }
            }
            .navigationTitle("Зміна Email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Скасувати") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isCodeSent ? "Підтвердити" : "Надіслати") {
                        Task { await handleConfirmationAction() }
                    }
                    .disabled(isConfirmationDisabled)
                }
            }
            .onAppear {
                newEmail = viewModel.currentUser?.email ?? ""
            }
        }
    }

    private var isConfirmationDisabled: Bool {
        if viewModel.isSecurityProcessing {
            return true
        }

        if isCodeSent {
            return verificationCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        return newEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || currentPassword.isEmpty
    }

    private func handleConfirmationAction() async {
        if isCodeSent {
            let success = await viewModel.confirmEmailChange(
                actionCode: verificationCode,
                expectedEmail: newEmail.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            if success {
                dismiss()
            }
        } else {
            let success = await viewModel.changeEmail(newEmail: newEmail, currentPassword: currentPassword)
            if success {
                isCodeSent = true
            }
        }
    }
}
