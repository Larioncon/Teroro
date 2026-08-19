import SwiftUI

struct AddEmailPasswordSheetView: View {
    @ObservedObject var viewModel: SettingsVM
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    SecureField("Пароль", text: $password)
                    SecureField("Підтвердіть пароль", text: $confirmPassword)
                } footer: {
                    Text("Пароль повинен містити щонайменше 6 символів.")
                }
            }
            .navigationTitle("Додати email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Скасувати") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Зберегти") {
                        Task {
                            let success = await viewModel.addEmailAndPassword(
                                email: email,
                                password: password,
                                confirmPassword: confirmPassword
                            )
                            if success { dismiss() }
                        }
                    }
                    .disabled(
                        viewModel.isSecurityProcessing ||
                        email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        password.isEmpty ||
                        confirmPassword.isEmpty
                    )
                }
            }
        }
    }
}
