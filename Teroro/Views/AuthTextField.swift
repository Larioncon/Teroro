import SwiftUI

struct AuthTextField: View {
    let title: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var contentType: UITextContentType? = nil
    var submitLabel: SubmitLabel = .done
    var onSubmit: (() -> Void)? = nil

    @State private var isPasswordVisible: Bool = false
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .trailing) {
            Group {
                if isSecure && !isPasswordVisible {
                    SecureField(title, text: $text)
                        .textContentType(contentType)
                } else {
                    TextField(title, text: $text)
                        .keyboardType(keyboardType)
                        .textContentType(contentType)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(submitLabel)
            .onSubmit {
                onSubmit?()
            }
            .focused($isFocused)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .padding(.trailing, isSecure ? 40 : 0)

            if isSecure {
                Button(action: {
                    isPasswordVisible.toggle()
                }) {
                    Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 16)
            }
        }
        .frame(height: 54)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.secondary.opacity(isFocused ? 0.9 : 0.2), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

#Preview {
    @State var text = ""
    return VStack(spacing: 20) {
        AuthTextField(title: "Email", text: $text, keyboardType: .emailAddress)
        AuthTextField(title: "Password", text: $text, isSecure: true)
    }
    .padding()
}
