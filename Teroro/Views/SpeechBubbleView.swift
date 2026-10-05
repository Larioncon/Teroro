import SwiftUI

// MARK: - Speech Bubble Direction


public enum SpeechBubbleDirection: String, CaseIterable, Sendable {
    case right
    case left
    case bottomLeading
    case bottomTrailing
    case topLeading
    case topTrailing
    case top
    case bottom
}

// MARK: - Close Button Position

/// Положение кнопки закрытия (крестика)
public enum SpeechBubbleCloseButtonPosition: String, CaseIterable, Sendable {
    case insideTrailing
    case topTrailing
    case topLeading
}

// MARK: - Speech Bubble Shape

/// Векторный контур облачка сообщения с интегрированной стрелкой
public struct SpeechBubbleShape: Shape, @unchecked Sendable {
    public var direction: SpeechBubbleDirection
    public var cornerRadius: CGFloat
    public var arrowWidth: CGFloat
    public var arrowLength: CGFloat
    public var arrowOffset: CGFloat

    public init(
        direction: SpeechBubbleDirection = .right,
        cornerRadius: CGFloat = 16,
        arrowWidth: CGFloat = 14,
        arrowLength: CGFloat = 10,
        arrowOffset: CGFloat = 20
    ) {
        self.direction = direction
        self.cornerRadius = cornerRadius
        self.arrowWidth = arrowWidth
        self.arrowLength = arrowLength
        self.arrowOffset = arrowOffset
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()

        // Расчёт прямоугольника основного тела подсказки с учетом вылета стрелки
        let bodyRect: CGRect
        switch direction {
        case .left:
            bodyRect = CGRect(
                x: rect.minX + arrowLength,
                y: rect.minY,
                width: max(0, rect.width - arrowLength),
                height: rect.height
            )
        case .right:
            bodyRect = CGRect(
                x: rect.minX,
                y: rect.minY,
                width: max(0, rect.width - arrowLength),
                height: rect.height
            )
        case .topLeading, .topTrailing, .top:
            bodyRect = CGRect(
                x: rect.minX,
                y: rect.minY + arrowLength,
                width: rect.width,
                height: max(0, rect.height - arrowLength)
            )
        case .bottomLeading, .bottomTrailing, .bottom:
            bodyRect = CGRect(
                x: rect.minX,
                y: rect.minY,
                width: rect.width,
                height: max(0, rect.height - arrowLength)
            )
        }

        let radius = min(cornerRadius, min(bodyRect.width, bodyRect.height) / 2)

        // Начальная точка — сразу после верхнего левого угла на верхней грани
        path.move(to: CGPoint(x: bodyRect.minX + radius, y: bodyRect.minY))

        // MARK: 1. Верхняя грань
        if direction == .topLeading || direction == .topTrailing || direction == .top {
            let arrowCenterX: CGFloat
            switch direction {
            case .topLeading:
                arrowCenterX = min(
                    max(bodyRect.minX + radius + arrowOffset, bodyRect.minX + radius + arrowWidth / 2),
                    bodyRect.maxX - radius - arrowWidth / 2
                )
            case .topTrailing:
                arrowCenterX = max(
                    min(bodyRect.maxX - radius - arrowOffset, bodyRect.maxX - radius - arrowWidth / 2),
                    bodyRect.minX + radius + arrowWidth / 2
                )
            default:
                arrowCenterX = bodyRect.midX
            }

            let baseLeft = arrowCenterX - arrowWidth / 2
            let baseRight = arrowCenterX + arrowWidth / 2
            let tip = CGPoint(x: arrowCenterX, y: rect.minY)

            path.addLine(to: CGPoint(x: baseLeft, y: bodyRect.minY))
            path.addLine(to: tip)
            path.addLine(to: CGPoint(x: baseRight, y: bodyRect.minY))
        }
        path.addLine(to: CGPoint(x: bodyRect.maxX - radius, y: bodyRect.minY))

        // Верхний правый угол
        path.addArc(
            center: CGPoint(x: bodyRect.maxX - radius, y: bodyRect.minY + radius),
            radius: radius,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )

        // MARK: 2. Правая грань
        if direction == .right {
            let arrowCenterY = bodyRect.midY
            let baseTop = arrowCenterY - arrowWidth / 2
            let baseBottom = arrowCenterY + arrowWidth / 2
            let tip = CGPoint(x: rect.maxX, y: arrowCenterY)

            path.addLine(to: CGPoint(x: bodyRect.maxX, y: baseTop))
            path.addLine(to: tip)
            path.addLine(to: CGPoint(x: bodyRect.maxX, y: baseBottom))
        }
        path.addLine(to: CGPoint(x: bodyRect.maxX, y: bodyRect.maxY - radius))

        // Нижний правый угол
        path.addArc(
            center: CGPoint(x: bodyRect.maxX - radius, y: bodyRect.maxY - radius),
            radius: radius,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )

        // MARK: 3. Нижняя грань
        if direction == .bottomLeading || direction == .bottomTrailing || direction == .bottom {
            let arrowCenterX: CGFloat
            switch direction {
            case .bottomLeading:
                arrowCenterX = min(
                    max(bodyRect.minX + radius + arrowOffset, bodyRect.minX + radius + arrowWidth / 2),
                    bodyRect.maxX - radius - arrowWidth / 2
                )
            case .bottomTrailing:
                arrowCenterX = max(
                    min(bodyRect.maxX - radius - arrowOffset, bodyRect.maxX - radius - arrowWidth / 2),
                    bodyRect.minX + radius + arrowWidth / 2
                )
            default:
                arrowCenterX = bodyRect.midX
            }

            let baseRight = arrowCenterX + arrowWidth / 2
            let baseLeft = arrowCenterX - arrowWidth / 2
            let tip = CGPoint(x: arrowCenterX, y: rect.maxY)

            path.addLine(to: CGPoint(x: baseRight, y: bodyRect.maxY))
            path.addLine(to: tip)
            path.addLine(to: CGPoint(x: baseLeft, y: bodyRect.maxY))
        }
        path.addLine(to: CGPoint(x: bodyRect.minX + radius, y: bodyRect.maxY))

        // Нижний левый угол
        path.addArc(
            center: CGPoint(x: bodyRect.minX + radius, y: bodyRect.maxY - radius),
            radius: radius,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )

        // MARK: 4. Левая грань
        if direction == .left {
            let arrowCenterY = bodyRect.midY
            let baseBottom = arrowCenterY + arrowWidth / 2
            let baseTop = arrowCenterY - arrowWidth / 2
            let tip = CGPoint(x: rect.minX, y: arrowCenterY)

            path.addLine(to: CGPoint(x: bodyRect.minX, y: baseBottom))
            path.addLine(to: tip)
            path.addLine(to: CGPoint(x: bodyRect.minX, y: baseTop))
        }
        path.addLine(to: CGPoint(x: bodyRect.minX, y: bodyRect.minY + radius))

        // Верхний левый угол
        path.addArc(
            center: CGPoint(x: bodyRect.minX + radius, y: bodyRect.minY + radius),
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )

        path.closeSubpath()
        return path
    }
}

// MARK: - Speech Bubble View

/// Универсальный компонент подсказки (Speech Bubble)
public struct SpeechBubbleView<Content: View>: View {
    public let direction: SpeechBubbleDirection
    public let backgroundColor: Color
    public let foregroundColor: Color
    public let cornerRadius: CGFloat
    public let arrowWidth: CGFloat
    public let arrowLength: CGFloat
    public let arrowOffset: CGFloat
    public let contentPadding: EdgeInsets
    public let shadowColor: Color
    public let shadowRadius: CGFloat
    public let shadowX: CGFloat
    public let shadowY: CGFloat
    public let closeButtonPosition: SpeechBubbleCloseButtonPosition
    public let onClose: (() -> Void)?
    @ViewBuilder public let content: () -> Content

    /// Полный инициализатор с кастомным содержимым
    public init(
        direction: SpeechBubbleDirection = .right,
        backgroundColor: Color = .blue,
        foregroundColor: Color = .white,
        cornerRadius: CGFloat = 16,
        arrowWidth: CGFloat = 14,
        arrowLength: CGFloat = 10,
        arrowOffset: CGFloat = 20,
        contentPadding: EdgeInsets = EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14),
        shadowColor: Color = .black.opacity(0.15),
        shadowRadius: CGFloat = 6,
        shadowX: CGFloat = 0,
        shadowY: CGFloat = 3,
        closeButtonPosition: SpeechBubbleCloseButtonPosition = .insideTrailing,
        onClose: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.direction = direction
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.cornerRadius = cornerRadius
        self.arrowWidth = arrowWidth
        self.arrowLength = arrowLength
        self.arrowOffset = arrowOffset
        self.contentPadding = contentPadding
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.shadowX = shadowX
        self.shadowY = shadowY
        self.closeButtonPosition = closeButtonPosition
        self.onClose = onClose
        self.content = content
    }

    /// Внутренние отступы для компенсации выступающей стрелки
    private var arrowInsets: EdgeInsets {
        switch direction {
        case .left:
            return EdgeInsets(top: 0, leading: arrowLength, bottom: 0, trailing: 0)
        case .right:
            return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: arrowLength)
        case .topLeading, .topTrailing, .top:
            return EdgeInsets(top: arrowLength, leading: 0, bottom: 0, trailing: 0)
        case .bottomLeading, .bottomTrailing, .bottom:
            return EdgeInsets(top: 0, leading: 0, bottom: arrowLength, trailing: 0)
        }
    }

    private var closeBadgeAlignment: Alignment {
        switch closeButtonPosition {
        case .topLeading:
            return .topLeading
        case .topTrailing, .insideTrailing:
            return .topTrailing
        }
    }

    @ViewBuilder
    private var cornerCloseButtonBadge: some View {
        if let onClose = onClose, closeButtonPosition != .insideTrailing {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(foregroundColor)
                    .frame(width: 22, height: 22)
                    .background(
                        Circle()
                            .fill(backgroundColor)
                            .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 1)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)
            .offset(
                x: closeButtonPosition == .topLeading ? -4 : 4,
                y: -4
            )
        }
    }

    public var body: some View {
        content()
            .padding(contentPadding)
            .padding(arrowInsets)
            .background(
                SpeechBubbleShape(
                    direction: direction,
                    cornerRadius: cornerRadius,
                    arrowWidth: arrowWidth,
                    arrowLength: arrowLength,
                    arrowOffset: arrowOffset
                )
                .fill(backgroundColor)
                .shadow(color: shadowColor, radius: shadowRadius, x: shadowX, y: shadowY)
            )
            .overlay(alignment: closeBadgeAlignment) {
                cornerCloseButtonBadge
            }
    }
}

// MARK: - Convenience Initializer for Text & Icon

extension SpeechBubbleView where Content == AnyView {
    /// Удобный инициализатор для подсказок с текстом, иконкой и настраиваемой кнопкой закрытия
    public init(
        _ message: String,
        icon: String? = nil,
        direction: SpeechBubbleDirection = .right,
        backgroundColor: Color = .blue,
        foregroundColor: Color = .white,
        font: Font = .system(size: 14, weight: .medium),
        cornerRadius: CGFloat = 16,
        arrowWidth: CGFloat = 14,
        arrowLength: CGFloat = 10,
        arrowOffset: CGFloat = 20,
        contentPadding: EdgeInsets = EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14),
        shadowColor: Color = .black.opacity(0.15),
        shadowRadius: CGFloat = 6,
        shadowX: CGFloat = 0,
        shadowY: CGFloat = 3,
        closeButtonPosition: SpeechBubbleCloseButtonPosition = .insideTrailing,
        onClose: (() -> Void)? = nil
    ) {
        self.init(
            direction: direction,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            cornerRadius: cornerRadius,
            arrowWidth: arrowWidth,
            arrowLength: arrowLength,
            arrowOffset: arrowOffset,
            contentPadding: contentPadding,
            shadowColor: shadowColor,
            shadowRadius: shadowRadius,
            shadowX: shadowX,
            shadowY: shadowY,
            closeButtonPosition: closeButtonPosition,
            onClose: onClose
        ) {
            AnyView(
                HStack(alignment: .center, spacing: 12) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(foregroundColor)
                    }

                    Text(message)
                        .font(font)
                        .foregroundColor(foregroundColor)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if let onClose = onClose, closeButtonPosition == .insideTrailing {
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(foregroundColor.opacity(0.85))
                                .padding(4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            )
        }
    }
}

// MARK: - Preview

#Preview("All Directions & Close Positions") {
    ScrollView {
        VStack(spacing: 24) {
            // Пример 1: Как на скриншоте (стрелка вправо + иконка локации)
            SpeechBubbleView(
                "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor.",
                icon: "location.fill",
                direction: .right
            )

            // Пример 2: Стрелка влево
            SpeechBubbleView(
                "Підказка зі стрілкою вліво. Зручно для вказівки на меню зліва.",
                icon: "arrow.left.circle.fill",
                direction: .left,
                backgroundColor: .indigo
            )

            // Пример 3: Стрелка вниз-слева
            SpeechBubbleView(
                "Стрілка вниз-зліва вказує на кнопку або вкладку знизу.",
                icon: "calendar",
                direction: .bottomLeading,
                backgroundColor: .teal
            )

            // Пример 4: Стрелка вниз-справа
            SpeechBubbleView(
                "Стрілка вниз-справа вказує на профіль або дію в кутку.",
                icon: "person.crop.circle.fill",
                direction: .bottomTrailing,
                backgroundColor: .blue
            )

            // Пример 5: Стрелка сверху-слева
            SpeechBubbleView(
                "Стрілка зверху-зліва для верхнього навігаційного бару.",
                icon: "chevron.left.circle.fill",
                direction: .topLeading,
                backgroundColor: .purple
            )

            // Пример 6: Стрелка сверху-справа
            SpeechBubbleView(
                "Стрілка зверху-справа вказує на налаштування або фільтр.",
                icon: "slider.horizontal.3",
                direction: .topTrailing,
                backgroundColor: .orange
            )

            Divider().padding(.vertical, 8)

            // Пример 7: Крестик внутри справа (.insideTrailing)
            SpeechBubbleView(
                "Крестик всередині: closeButtonPosition = .insideTrailing",
                icon: "lightbulb.fill",
                direction: .bottom,
                backgroundColor: .cyan,
                closeButtonPosition: .insideTrailing,
                onClose: {
                    print("Dismissed inside")
                }
            )

            // Пример 8: Крестик сверху-справа (.topTrailing)
            SpeechBubbleView(
                "Крестик зверху-справа: closeButtonPosition = .topTrailing",
                icon: "lightbulb.fill",
                direction: .bottom,
                backgroundColor: .mint,
                closeButtonPosition: .topTrailing,
                onClose: {
                    print("Dismissed topTrailing")
                }
            )

            // Пример 9: Крестик сверху-слева (.topLeading)
            SpeechBubbleView(
                "Крестик зверху-зліва: closeButtonPosition = .topLeading",
                icon: "lightbulb.fill",
                direction: .bottom,
                backgroundColor: .pink,
                closeButtonPosition: .topLeading,
                onClose: {
                    print("Dismissed topLeading")
                }
            )
        }
        .padding(24)
    }
    .background(Color(.systemGroupedBackground))
}
