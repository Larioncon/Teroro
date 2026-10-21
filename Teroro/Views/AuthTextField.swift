import SwiftUI

struct AuthTextField: View {
    let title: LocalizedStringKey
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var contentType: UITextContentType? = nil
    var textInputAutocapitalization: TextInputAutocapitalization = .never
    var submitLabel: SubmitLabel = .done
    var onSubmit: (() -> Void)? = nil

    @State private var isPasswordVisible: Bool = false
    @FocusState private var isFocused: Bool

    init(
        title: LocalizedStringKey,
        text: Binding<String>,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default,
        contentType: UITextContentType? = nil,
        textInputAutocapitalization: TextInputAutocapitalization = .never,
        submitLabel: SubmitLabel = .done,
        onSubmit: (() -> Void)? = nil
    ) {
        self.title = title
        self._text = text
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.contentType = contentType
        self.textInputAutocapitalization = textInputAutocapitalization
        self.submitLabel = submitLabel
        self.onSubmit = onSubmit
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            Group {
                if isSecure && !isPasswordVisible {
                    SecureField(text: $text, prompt: prompt) { fieldLabel }
                        .textContentType(contentType)
                } else {
                    TextField(text: $text, prompt: prompt) { fieldLabel }
                        .keyboardType(keyboardType)
                        .textContentType(contentType)
                }
            }
            .textInputAutocapitalization(textInputAutocapitalization)
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

    private var fieldLabel: Text {
        Text(title)
    }

    private var prompt: Text? { fieldLabel }
}

#Preview {
    @State var text = ""
    return VStack(spacing: 20) {
        AuthTextField(title: "form.email.placeholder", text: $text, keyboardType: .emailAddress)
        AuthTextField(title: "security.password.placeholder", text: $text, isSecure: true)
    }
    .padding()
}
