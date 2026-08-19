import SwiftUI
import UIKit

struct PasscodeSheetView: View {
    @ObservedObject var viewModel: SettingsVM
    @Environment(\.dismiss) private var dismiss
    @State private var passcodeFlow: PasscodeSetupFlow?

    var body: some View {
        NavigationStack {
            Form {
                PasscodeActionGroup(
                    isPasscodeEnabled: viewModel.isPasscodeEnabled,
                    onTurnOff: turnPasscodeOff,
                    onChange: showPasscodeFlow
                )

                PasscodeSecurityGroup(viewModel: viewModel)
                    .disabled(!viewModel.isPasscodeEnabled)
            }
            .navigationTitle("Блокування код-паролем")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundStyle(.primary)
                            .frame(width: 33, height: 33)
                    }
                    .accessibilityLabel("Назад")
                }
            }
            .fullScreenCover(item: $passcodeFlow) { _ in
                PasscodeSetupEntryView(viewModel: viewModel)
            }
        }
    }

    private func showPasscodeFlow() {
        passcodeFlow = PasscodeSetupFlow()
    }

    private func turnPasscodeOff() {
        viewModel.savePasscode("")
    }
}

private struct PasscodeActionGroup: View {
    let isPasscodeEnabled: Bool
    let onTurnOff: () -> Void
    let onChange: () -> Void

    var body: some View {
        Section {
            if isPasscodeEnabled {
                Button("Вимкнути код-пароль", action: onTurnOff)
                    .foregroundStyle(.red)

                Button("Змінити код-пароль", action: onChange)
            } else {
                Button("Увімкнути код-пароль", action: onChange)
            }
        } footer: {
            Text("Коли код-пароль увімкнено, Timexo буде запитувати його при запуску або після повернення у застосунок згідно з Auto-Lock.")
        }
    }
}

private struct PasscodeSecurityGroup: View {
    @ObservedObject var viewModel: SettingsVM

    var body: some View {
        Section {
            Picker("Auto-Lock", selection: Binding(get: {
                viewModel.passcodeAutoLockOption
            }, set: { option in
                viewModel.passcodeAutoLockOption = option
            })) {
                ForEach(PasscodeAutoLockOption.allCases) { option in
                    Text(option.title)
                        .tag(option)
                }
            }

            Toggle(isOn: Binding(get: {
                viewModel.isFaceIDEnabled
            }, set: { newValue in
                viewModel.toggleFaceID(enabled: newValue)
            })) {
                Label("Розблокування з Face ID", systemImage: "faceid")
            }
        }
    }
}

private struct PasscodeSetupFlow: Identifiable {
    let id = UUID()
}

private struct PasscodeSetupEntryView: View {
    @ObservedObject var viewModel: SettingsVM
    @Environment(\.dismiss) private var dismiss
    @State private var firstPasscode = ""
    @State private var currentPasscode = ""
    @State private var isConfirming = false
    @State private var errorMessage: String?

    private let passcodeLength = 6

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: 28) {
                        Text(isConfirming ? "Підтвердіть код-пароль Timexo" : "Введіть код-пароль Timexo")
                            .font(.title2)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)

                        PasscodeDotsView(filledCount: currentPasscode.count, totalCount: passcodeLength, color: .primary)

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.callout)
                                .foregroundStyle(.red)
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("Блокування код-паролем")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Назад")
                }
            }
        }
        .overlay(alignment: .bottom) {
            HiddenPasscodeInput(text: $currentPasscode)
                .frame(width: 1, height: 1)
                .opacity(0.01)
        }
        .onChange(of: currentPasscode) { newValue in
            handlePasscodeChange(newValue)
        }
    }

    private func handlePasscodeChange(_ value: String) {
        let digits = value.filter(\.isNumber)
        if digits != value || digits.count > passcodeLength {
            currentPasscode = String(digits.prefix(passcodeLength))
            return
        }

        guard digits.count == passcodeLength else { return }

        if isConfirming {
            if digits == firstPasscode {
                viewModel.savePasscode(digits)
                dismiss()
            } else {
                errorMessage = "Коди-паролі не співпадають"
                firstPasscode = ""
                currentPasscode = ""
                isConfirming = false
            }
        } else {
            firstPasscode = digits
            currentPasscode = ""
            isConfirming = true
            errorMessage = nil
        }
    }
}

private struct HiddenPasscodeInput: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.keyboardType = .numberPad
        textField.textContentType = .oneTimeCode
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textChanged(_:)), for: .editingChanged)

        Task { @MainActor in
            textField.becomeFirstResponder()
        }

        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }

        if !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding private var text: String

        init(text: Binding<String>) {
            _text = text
        }

        @objc func textChanged(_ textField: UITextField) {
            text = textField.text ?? ""
        }
    }
}
