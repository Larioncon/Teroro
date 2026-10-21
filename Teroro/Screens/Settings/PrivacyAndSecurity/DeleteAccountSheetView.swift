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

                            Text("security.account.delete.warning.title")
                                .font(.headline)
                                .foregroundStyle(.red)
                        }

                        Text("security.account.delete.warning.description")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                if viewModel.hasPassword || (!viewModel.isGoogleLinked && !viewModel.isAppleLinked) {
                    Section("security.confirmation.email.password.section") {
                        TextField("form.email.placeholder", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .disabled(true)
                            .foregroundStyle(.secondary)

                        SecureField("security.enter.your.pwd", text: $password)

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
                                    Text("security.account.delete.confirm.button")
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
                    Section("security.confirmation.google.section") {
                        Button {
                            Task {
                                let success = await viewModel.deleteAccountWithGoogle()
                                if success { dismiss() }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "g.circle.fill")
                                    .foregroundStyle(.red)
                                Text("security.confirm.google.delete")
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
                    Section("security.confirmation.apple.section") {
                        Button {
                            Task {
                                let success = await viewModel.deleteAccountWithApple()
                                if success { dismiss() }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "apple.logo")
                                    .foregroundStyle(.red)
                                Text("security.confirm.apple.delete")
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
            .navigationTitle("security.account.delete.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                        .disabled(viewModel.isSecurityProcessing)
                }
            }
            .onAppear {
                email = viewModel.currentUser?.email ?? ""
            }
        }
    }
}
