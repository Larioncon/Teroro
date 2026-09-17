import SwiftUI

struct DeleteAccountSheetView: View {
    @ObservedObject var viewModel: SettingsVM
    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
    @State private var password: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title2)
                                .foregroundStyle(.red)

                            Text("Увага! Дія незворотна")
                                .font(.headline)
                                .foregroundStyle(.red)
                        }

                        Text("Видалення акаунту призведе до повного та безповоротного знищення всіх ваших даних, включаючи збережені терміни, профіль та налаштування.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                if viewModel.hasPassword || (!viewModel.isGoogleLinked && !viewModel.isAppleLinked) {
                    Section("Підтвердження через Email / Пароль") {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .disabled(true)
                            .foregroundStyle(.secondary)

                        SecureField("Введіть ваш пароль", text: $password)

                        Button(role: .destructive) {
                            Task {
                                let success = await viewModel.deleteAccountWithPassword(password: password)
                                if success { dismiss() }
                            }
                        } label: {
                            HStack {
                                Spacer()
                                if viewModel.isSecurityProcessing {
                                    ProgressView()
                                        .tint(.red)
                                } else {
                                    Text("Підтвердити та видалити акаунт")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.red)
                                }
                                Spacer()
                            }
                        }
                        .disabled(viewModel.isSecurityProcessing || password.isEmpty)
                    }
                }

                if viewModel.isGoogleLinked {
                    Section("Підтвердження через Google") {
                        Button {
                            Task {
                                let success = await viewModel.deleteAccountWithGoogle()
                                if success { dismiss() }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "g.circle.fill")
                                    .foregroundStyle(.red)
                                Text("Підтвердити через Google та видалити")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.red)
                                Spacer()
                                if viewModel.isSecurityProcessing {
                                    ProgressView()
                                        .tint(.red)
                                }
                            }
                        }
                        .disabled(viewModel.isSecurityProcessing)
                    }
                }

                if viewModel.isAppleLinked {
                    Section("Підтвердження через Apple") {
                        Button {
                            Task {
                                let success = await viewModel.deleteAccountWithApple()
                                if success { dismiss() }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "apple.logo")
                                    .foregroundStyle(.red)
                                Text("Підтвердити через Apple та видалити")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.red)
                                Spacer()
                                if viewModel.isSecurityProcessing {
                                    ProgressView()
                                        .tint(.red)
                                }
                            }
                        }
                        .disabled(viewModel.isSecurityProcessing)
                    }
                }
            }
            .navigationTitle("Видалення акаунту")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Скасувати") { dismiss() }
                        .disabled(viewModel.isSecurityProcessing)
                }
            }
            .onAppear {
                email = viewModel.currentUser?.email ?? ""
            }
        }
    }
}
