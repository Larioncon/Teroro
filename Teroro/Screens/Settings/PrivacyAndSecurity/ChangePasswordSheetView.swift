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
                    SecureField("security.current.pwd", text: $currentPassword)
                    SecureField("security.new.pwd", text: $newPassword)
                    SecureField("security.confirm.new.pwd", text: $confirmPassword)
                } footer: {
                    Text("security.password.requirements")
                }
            }
            .navigationTitle("security.change.pwd.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") {
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
