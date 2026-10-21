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
                    TextField("form.email.placeholder", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    SecureField("security.password.placeholder", text: $password)
                    SecureField("auth.password.confirm.label", text: $confirmPassword)
                } footer: {
                    Text("security.password.requirements")
                }
            }
            .navigationTitle("security.email.add.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") {
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
