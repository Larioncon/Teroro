import SwiftUI

struct PasscodeKeyButton: View {
    let digit: String
    let letters: String
    let onDigit: (String) -> Void

    var body: some View {
        Button {
            onDigit(digit)
        } label: {
            VStack(spacing: 0) {
                Text(digit)
                    .font(.system(size: 48, weight: .regular, design: .rounded))
                    .minimumScaleFactor(0.7)

                Text(letters)
                    .font(.caption.bold())
                    .frame(height: 18)
                    .opacity(letters.isEmpty ? 0 : 1)
            }
            .foregroundStyle(.white)
            .frame(width: 86, height: 86)
            .background(.white.opacity(0.12), in: Circle())
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(digit)
    }
}
