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
                    TextField("security.email.new.placeholder", text: $newEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .disabled(isCodeSent)

                    SecureField("security.current.pwd", text: $currentPassword)
                        .disabled(isCodeSent)
                } header: {
                    Text("security.email.new.placeholder")
                } footer: {
                    if isCodeSent {
                        Text("Поточний email: \(viewModel.currentUser?.email ?? "—"). Введіть код з листа Firebase, який прийшов на новий email. Якщо лист містить посилання, використайте значення параметра oobCode.")
                    } else {
                        Text("Поточний email: \(viewModel.currentUser?.email ?? "—"). Після підтвердження паролю, надійде лист на новий email для верифікації.")
                    }
                }

                if isCodeSent {
                    Section("security.confirmation.section") {
                        TextField("security.email.verification.code.field", text: $verificationCode)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }
            }
            .navigationTitle("security.change.email.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isCodeSent ? "common.confirm" : "security.send") {
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
