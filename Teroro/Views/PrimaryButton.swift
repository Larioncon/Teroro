import SwiftUI

enum ButtonVisualStyle {
    case primary
    case primaryWhiteText
//    case secondary
    case siwa
    case siwg

    var background: Color {
        switch self {
        case .primary, .primaryWhiteText:
            return .primaryColor
//        case .secondary:
//            return .pwOrangeBg
        case .siwa, .siwg:
            return .white
        }
    }

    var textColor: Color {
        switch self {
        case .primary:
            return .primaryBlackText
        case .primaryWhiteText:
            return .white
//        case .secondary:
//            return .primaryBlackText
        case .siwa, .siwg:
            return .black
        }
    }

    var border: (Color, CGFloat)? {
        switch self {
//        case .secondary:
//            return (.primaryOrange, 1)
        case .siwa, .siwg:
            return (.gray, 1)
        default:
            return nil
        }
    }

    var iconAssetName: String? {
        switch self {
        case .siwa:
            return "appleIc"
        case .siwg:
            return "googleIc"
        default:
            return nil
        }
    }
}

struct PrimaryButton: View {
    let title: String
    let style: ButtonVisualStyle
    let frameHeight: CGFloat
    let action: () -> Void

    init(
        title: String,
        style: ButtonVisualStyle,
        frameHeight: CGFloat = 48,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.frameHeight = frameHeight
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let icon = style.iconAssetName {
                    Image(icon)
                        .resizable()
                        .frame(width: 24, height: 24)
                }

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(style.textColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: frameHeight)
            .background(style.background)
            .clipShape(Capsule())
            .overlay(
                RoundedRectangle(cornerRadius: frameHeight / 2)
                    .stroke(style.border?.0 ?? .clear, lineWidth: style.border?.1 ?? 0)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

extension Color {
    // Minimal defaults; feel free to replace with Assets later.
    static let primaryColor = Color.blue
    
    static let primaryBlackText = Color.primary
}

#Preview {
    VStack(spacing: 12) {
        PrimaryButton(title: "Продовжити", style: .primary) {}
//        PrimaryButton(title: "Secondary", style: .secondary) {}
    }
    .padding()
}

