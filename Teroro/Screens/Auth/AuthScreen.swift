import SwiftUI
import UIKit

struct AuthScreen: View {
    @ObservedObject var viewModel: AuthVM
    @FocusState private var focusedField: Field?
    @State private var presentingViewController: UIViewController?
    @State private var isShowingAppleStubAlert: Bool = false

    enum Field: Hashable {
        case email
        case password
        case confirm
    }

    var body: some View {
        ZStack {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header

                        VStack(spacing: 12) {
                            textField(
                                title: "Email",
                                text: $viewModel.email,
                                keyboard: .emailAddress,
                                contentType: .emailAddress,
                                submit: .next
                            )
                            .focused($focusedField, equals: .email)

                            secureField(
                                title: "Password",
                                text: $viewModel.password,
                                contentType: .password,
                                submit: viewModel.mode == .signUp ? .next : .go
                            )
                            .focused($focusedField, equals: .password)

                            if viewModel.mode == .signUp {
                                secureField(
                                    title: "Confirm password",
                                    text: $viewModel.confirmPassword,
                                    contentType: .newPassword,
                                    submit: .go
                                )
                                .focused($focusedField, equals: .confirm)
                                .transition(.opacity.combined(with: .move(edge: .trailing)))
                            }
                        }
                        .animation(.easeInOut(duration: 0.25), value: viewModel.mode)

                        if viewModel.mode == .signIn {
                            Button("Forgot password?") {
                                viewModel.resetPassword()
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.blue)
                            .padding(.top, 2)
                        }

                        PrimaryButton(
                            title: viewModel.primaryButtonTitle,
                            style: .primaryWhiteText,
                            frameHeight: 54
                        ) {
                            focusedField = nil
                            viewModel.submit()
                        }
                        .disabled(viewModel.isLoading)
                        .opacity(viewModel.isLoading ? 0.7 : 1)

                        socialSection
                            .padding(.top, 6)

                        toggleModeFooter
                            .padding(.top, 10)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                }
                .scrollDismissesKeyboard(.interactively)
                .background(ViewControllerReader(viewController: $presentingViewController))
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Готово") { focusedField = nil }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
            }
            .alert("Помилка", isPresented: Binding(get: {
                viewModel.alertMessage != nil
            }, set: { newValue in
                if !newValue { viewModel.alertMessage = nil }
            }), actions: {
                Button("OK") { viewModel.alertMessage = nil }
            }, message: {
                Text(viewModel.alertMessage ?? "")
            })
            .alert("Незабаром", isPresented: $isShowingAppleStubAlert, actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                Text("Опція входу через Apple зʼявиться пізніше.")
            })

            if viewModel.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.mode == .signUp ? "Create account" : "Welcome back")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.primary)
                .transition(.opacity.combined(with: .move(edge: .trailing)))

            Text(viewModel.mode == .signUp
                 ? "Create an account to start using Teroro."
                 : "Sign in to continue.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.mode)
    }

    private var toggleModeFooter: some View {
        HStack(spacing: 6) {
            Text(viewModel.togglePrompt)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                focusedField = nil
                viewModel.toggleMode()
            } label: {
                Text(viewModel.toggleActionTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.blue)
                    .underline(true, color: .blue)
            }
            .accessibilityLabel(viewModel.toggleActionTitle)

            Spacer(minLength: 0)
        }
    }

    private var socialSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.25))
                    .frame(height: 1)
                Text("або")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                Rectangle()
                    .fill(Color.secondary.opacity(0.25))
                    .frame(height: 1)
            }

            PrimaryButton(title: "Continue with Apple", style: .siwa, frameHeight: 52) {
                focusedField = nil
                isShowingAppleStubAlert = true
            }

            PrimaryButton(title: "Continue with Google", style: .siwg, frameHeight: 52) {
                focusedField = nil
                viewModel.signInWithGoogle(presenting: presentingViewController)
            }
            .disabled(viewModel.isLoading)
            .opacity(viewModel.isLoading ? 0.7 : 1)
        }
    }

    private func textField(
        title: String,
        text: Binding<String>,
        keyboard: UIKeyboardType,
        contentType: UITextContentType?,
        submit: SubmitLabel
    ) -> some View {
        TextField(title, text: text)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(keyboard)
            .textContentType(contentType)
            .submitLabel(submit)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
            )
            .onSubmit {
                switch focusedField {
                case .email:
                    focusedField = .password
                case .password:
                    focusedField = viewModel.mode == .signUp ? .confirm : nil
                    if viewModel.mode == .signIn { viewModel.submit() }
                case .confirm:
                    focusedField = nil
                    viewModel.submit()
                default:
                    break
                }
            }
    }

    private func secureField(
        title: String,
        text: Binding<String>,
        contentType: UITextContentType?,
        submit: SubmitLabel
    ) -> some View {
        SecureField(title, text: text)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .textContentType(contentType)
            .submitLabel(submit)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
            )
            .onSubmit {
                switch focusedField {
                case .password:
                    focusedField = viewModel.mode == .signUp ? .confirm : nil
                    if viewModel.mode == .signIn { viewModel.submit() }
                case .confirm:
                    focusedField = nil
                    viewModel.submit()
                default:
                    break
                }
            }
    }
}

private struct ViewControllerReader: UIViewControllerRepresentable {
    @Binding var viewController: UIViewController?

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        DispatchQueue.main.async {
            // Capture the nearest UIViewController to present GoogleSignIn.
            self.viewController = controller
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // no-op
    }
}

#Preview {
    AuthScreen(viewModel: AuthVM())
}
