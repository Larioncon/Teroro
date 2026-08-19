import LocalAuthentication
import SwiftUI
import UIKit

struct AppLockScreen: View {
    let passcode: String
    let isFaceIDEnabled: Bool
    let onUnlock: () -> Void

    @State private var enteredPasscode = ""
    @State private var didTryBiometrics = false
    @State private var dotsShakeOffset = 0.0

    private var passcodeLength: Int {
        max(passcode.count, 1)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.26, green: 0.08, blue: 0.28),
                    Color(red: 0.30, green: 0.14, blue: 0.08),
                    Color(red: 0.04, green: 0.12, blue: 0.24)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.white)
                    .padding(.top, 84)

                Spacer()
                    .frame(height: 100)

                VStack(spacing: 30) {
                    Text("Enter your Timexo Passcode")
                        .font(.system(size: 28, weight: .regular))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)

                    PasscodeDotsView(filledCount: enteredPasscode.count, totalCount: passcodeLength, color: .white)
                        .offset(x: dotsShakeOffset)
                }

                Spacer(minLength: 72)

                NumericPasscodePad(onDigit: appendDigit)

                Spacer(minLength: 10)

                HStack {
                    if isFaceIDEnabled {
                        Button("Face ID", action: authenticateWithBiometrics)
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    Button("Delete", action: deleteDigit)
                        .foregroundStyle(.white)
                        .padding(.bottom, 10)
                }
                .font(.title3)
                .padding(.horizontal, 58)
                .padding(.bottom, 40)
            }
        }
        .onAppear(perform: authenticateWithBiometricsIfNeeded)
    }

    private func appendDigit(_ digit: String) {
        guard enteredPasscode.count < passcodeLength else { return }
        enteredPasscode.append(digit)

        guard enteredPasscode.count == passcodeLength else { return }

        if enteredPasscode == passcode {
            onUnlock()
        } else {
            rejectPasscode()
        }
    }

    private func deleteDigit() {
        guard !enteredPasscode.isEmpty else { return }
        enteredPasscode.removeLast()
    }

    private func rejectPasscode() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)

        withAnimation(.linear(duration: 0.06).repeatCount(5, autoreverses: true)) {
            dotsShakeOffset = 14
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(360))
            dotsShakeOffset = 0
            enteredPasscode = ""
        }
    }

    private func authenticateWithBiometricsIfNeeded() {
        guard isFaceIDEnabled, !didTryBiometrics else { return }
        didTryBiometrics = true
        authenticateWithBiometrics()
    }

    private func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock Timexo") { success, _ in
            Task { @MainActor in
                if success {
                    onUnlock()
                } else {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }
    }
}
