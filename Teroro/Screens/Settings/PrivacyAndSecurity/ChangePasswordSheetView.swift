import SwiftUI

struct ChangePasswordSheetView: View {
    @ObservedObject var viewModel: SettingsVM
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Поточний пароль", text: $currentPassword)
                    SecureField("Новий пароль", text: $newPassword)
                    SecureField("Підтвердіть новий пароль", text: $confirmPassword)
                } footer: {
                    Text("Пароль повинен містити щонайменше 6 символів.")
                }
            }
            .navigationTitle("Зміна паролю")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Скасувати") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Зберегти") {
                        Task {
                            let success = await viewModel.changePassword(
                                newPassword: newPassword,
                                confirmPassword: confirmPassword,
                                currentPassword: currentPassword
                            )
                            if success { dismiss() }
                        }
                    }
                    .disabled(viewModel.isSecurityProcessing || newPassword.isEmpty || confirmPassword.isEmpty || currentPassword.isEmpty)
                }
            }
        }
    }
}
