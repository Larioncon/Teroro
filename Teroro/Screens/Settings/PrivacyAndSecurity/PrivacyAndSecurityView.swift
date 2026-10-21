import SwiftUI

struct PrivacyAndSecurityView: View {
    @ObservedObject var viewModel: SettingsVM
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var toasts: [Toast] = []

    var body: some View {
        List {
            Section {
                Button {
                    viewModel.isPasscodeSheetPresented = true
                } label: {
                    HStack {
                        Label {
                            Text(languageManager.localizedString(forKey: "security_passcode"))
                        } icon: {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.blue)
                        }
                        Spacer()
                        Text(languageManager.localizedString(forKey: viewModel.isPasscodeEnabled ? "security_enabled" : "security_disabled"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.forward")
                            .font(.footnote.bold())
                            .foregroundColor(.gray)
                    }
                }
                .foregroundStyle(.primary)

                if viewModel.hasPassword {
                    Button {
                        viewModel.isChangePasswordSheetPresented = true
                    } label: {
                        HStack {
                            Label {
                                Text(languageManager.localizedString(forKey: "security_change_password"))
                            } icon: {
                                Image(systemName: "key.fill")
                                    .foregroundStyle(.blue)
                            }
                            Spacer()
                            Image(systemName: "chevron.forward")
                                .font(.footnote.bold())
                                .foregroundColor(.gray)
                        }
                    }
                    .foregroundStyle(.primary)
                }

                Button {
                    viewModel.isChangeEmailSheetPresented = true
                } label: {
                    HStack {
                        Label {
                            Text(languageManager.localizedString(forKey: "security_change_email"))
                        } icon: {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(.blue)
                        }
                        Spacer()
                        if !viewModel.hasPassword {
                            Text(languageManager.localizedString(forKey: "security_add_email"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Image(systemName: "chevron.forward")
                            .font(.footnote.bold())
                            .foregroundColor(.gray)
                    }
                }
                .foregroundStyle(.primary)
                .disabled(!viewModel.hasPassword)
            }

            Section(languageManager.localizedString(forKey: "security_signin_methods")) {
                SignInProviderRow(
                    title: "Apple",
                    systemImage: "apple.logo",
                    isLinked: viewModel.isAppleLinked,
                    isProcessing: viewModel.isSecurityProcessing
                ) {
                    Task { await viewModel.linkAppleProvider() }
                }
                .id("signin-apple-\(viewModel.isAppleLinked)")

                SignInProviderRow(
                    title: "Google",
                    systemImage: "g.circle.fill",
                    isLinked: viewModel.isGoogleLinked,
                    isProcessing: viewModel.isSecurityProcessing
                ) {
                    Task { await viewModel.linkGoogleProvider() }
                }
                .id("signin-google-\(viewModel.isGoogleLinked)")

                SignInProviderRow(
                    title: "Email / Password",
                    systemImage: "envelope.badge.fill",
                    isLinked: viewModel.hasPassword,
                    isProcessing: viewModel.isSecurityProcessing
                ) {
                    viewModel.isAddEmailPasswordSheetPresented = true
                }
                .id("signin-password-\(viewModel.hasPassword)")
            }

            Section {
                HStack {
                    Spacer(minLength: 0)
                    Button {
                        viewModel.initiateDeleteAccount()
                    } label: {
                        Text(languageManager.localizedString(forKey: "security_delete_account"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(.thinMaterial, in: Capsule(style: .continuous))
                            .overlay(
                                Capsule(style: .continuous)
                                    .strokeBorder(Color.red.opacity(0.35), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    Spacer(minLength: 0)
                }
                .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                .listRowBackground(Color.clear)
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .navigationTitle(languageManager.localizedString(forKey: "settings_privacy_and_security"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.isAddEmailPasswordSheetPresented) {
            AddEmailPasswordSheetView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.isChangePasswordSheetPresented) {
            ChangePasswordSheetView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.isChangeEmailSheetPresented) {
            ChangeEmailSheetView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.isPasscodeSheetPresented) {
            PasscodeSheetView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.isDeleteAccountSheetPresented) {
            DeleteAccountSheetView(viewModel: viewModel)
        }
//        .alert("Вимкніть код-пароль", isPresented: $viewModel.isPasscodeDisableRequiredAlertPresented) {
//            Button("Зрозуміло", role: .cancel) { }
//        } message: {
//            Text("Для видалення акаунту спочатку необхідно вимкнути код-пароль та Face ID у налаштуваннях безпеки.")
//        }
        .onChange(of: viewModel.isPasscodeDisableRequiredAlertPresented) { isPresented in
            if isPresented {
                withAnimation {
                    toasts.insert(
                        Toast(
                            title: languageManager.localizedString(forKey: "security_disable_passcode_toast_title"),
                            message: languageManager.localizedString(forKey: "security_disable_passcode_toast_message"),
                            symbol: "exclamationmark.shield.fill",
                            tint: .orange,
                            timing: .long
                        ),
                        at: 0
                    )
                }
                viewModel.isPasscodeDisableRequiredAlertPresented = false
            }
        }
        .toasts($toasts)
        .alert(languageManager.localizedString(forKey: "common_error"), isPresented: Binding(get: {
            viewModel.securityAlertMessage != nil
        }, set: { newValue in
            if !newValue { viewModel.securityAlertMessage = nil }
        }), actions: {
            Button("common_ok") { viewModel.securityAlertMessage = nil }
        }, message: {
            Text(viewModel.securityAlertMessage ?? "")
        })
        .alert(languageManager.localizedString(forKey: "common_success"), isPresented: Binding(get: {
            viewModel.securitySuccessMessage != nil
        }, set: { newValue in
            if !newValue { viewModel.securitySuccessMessage = nil }
        }), actions: {
            Button("common_ok") { viewModel.securitySuccessMessage = nil }
        }, message: {
            Text(viewModel.securitySuccessMessage ?? "")
        })
    }
}

private struct SignInProviderRow: View {
    let title: String
    let systemImage: String
    let isLinked: Bool
    let isProcessing: Bool
    let action: () -> Void

    var body: some View {
        HStack {
            Label {
                Text(title)
            } icon: {
                Image(systemName: systemImage)
                    .foregroundStyle(.blue)
            }

            Spacer()

            if isLinked {
                Text(LanguageManager.shared.localizedString(forKey: "security_connected"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Button(LanguageManager.shared.localizedString(forKey: "security_connect"), action: action)
                    .disabled(isProcessing)
            }
        }
    }
}
