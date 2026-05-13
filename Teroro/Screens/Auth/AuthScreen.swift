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
                            AuthTextField(
                                title: "Email",
                                text: $viewModel.email,
                                keyboardType: .emailAddress,
                                contentType: .emailAddress,
                                submitLabel: .next,
                                onSubmit: { focusedField = .password }
                            )
                            .focused($focusedField, equals: .email)

                            AuthTextField(
                                title: "Password",
                                text: $viewModel.password,
                                isSecure: true,
                                contentType: .password,
                                submitLabel: viewModel.mode == .signUp ? .next : .go,
                                onSubmit: {
                                    focusedField = viewModel.mode == .signUp ? .confirm : nil
                                    if viewModel.mode == .signIn { viewModel.submit() }
                                }
                            )
                            .focused($focusedField, equals: .password)

                            if viewModel.mode == .signUp {
                                AuthTextField(
                                    title: "Confirm password",
                                    text: $viewModel.confirmPassword,
                                    isSecure: true,
                                    contentType: .newPassword,
                                    submitLabel: .go,
                                    onSubmit: {
                                        focusedField = nil
                                        viewModel.submit()
                                    }
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
                 ? "Create an account to start using Timora."
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
