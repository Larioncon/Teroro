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

                    SecureField("Password", text: $password)
                    SecureField("Confirm password", text: $confirmPassword)
                } footer: {
                    Text("Пароль повинен містити щонайменше 8 символів, велику та малу літери, а також цифру.")
                }
            }
            .navigationTitle("Додати email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common_cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common_save") {
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
