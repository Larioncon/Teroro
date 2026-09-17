import SwiftUI

// MARK: - Toast Model
struct Toast: Identifiable, Equatable {
    let id: UUID = .init()
    var title: String
    var message: String?
    var symbol: String
    var tint: Color = .primary
    var isUserInteractionEnabled: Bool = true
    var timing: ToastFrame = .medium
    
    enum ToastFrame: TimeInterval {
        case short = 2.0
        case medium = 4.0
        case long = 6.0
    }
}

// MARK: - Toast Item View
struct ToastItemView: View {
    var toast: Toast
    var onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.symbol)
                .font(.title3)
                .foregroundStyle(toast.tint)
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(toast.title)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                if let message = toast.message {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
//                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .toastBackground()
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.6), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .padding(.horizontal, 16)
        .allowsHitTesting(toast.isUserInteractionEnabled)
    }
}

// MARK: - Toast Group View
struct ToastGroupView: View {
    @Binding var toasts: [Toast]
    
    var body: some View {
        ZStack(alignment: .top) {
            ForEach(Array(toasts.enumerated()), id: \.element.id) { index, toast in
                ToastItemView(toast: toast) {
                    removeToast(toast)
                }
                .scaleEffect(scaleFor(index: index))
                .offset(y: offsetFor(index: index))
                .opacity(opacityFor(index: index))
                .zIndex(Double(toasts.count - index))
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .scale(scale: 0.85).combined(with: .opacity)
                ))
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onEnded { value in
                            if abs(value.translation.height) > 20 || abs(value.translation.width) > 40 {
                                removeToast(toast)
                            }
                        }
                )
                .task {
                    try? await Task.sleep(nanoseconds: UInt64(toast.timing.rawValue * 1_000_000_000))
                    removeToast(toast)
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: toasts)
        .onChange(of: toasts.count) { _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func scaleFor(index: Int) -> CGFloat {
        let maxVisible = 3
        if index < maxVisible {
            return 1.0 - (CGFloat(index) * 0.05)
        }
        return 0.85
    }

    private func offsetFor(index: Int) -> CGFloat {
        let maxVisible = 3
        if index < maxVisible {
            return CGFloat(index) * -12
        }
        return CGFloat(maxVisible) * -12
    }

    private func opacityFor(index: Int) -> Double {
        let maxVisible = 3
        if index >= maxVisible {
            return 0.0
        }
        return 1.0 - (Double(index) * 0.2)
    }

    @MainActor
    private func removeToast(_ toast: Toast) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            toasts.removeAll(where: { $0.id == toast.id })
        }
    }
}

// MARK: - ViewModifier & Extension
struct ToastModifier: ViewModifier {
    @Binding var toasts: [Toast]

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if !toasts.isEmpty {
                    ToastGroupView(toasts: $toasts)
                        .padding(.top, 8)
                }
            }
    }
}
extension View {
    @ViewBuilder
    func toastBackground(cornerRadius: CGFloat = 20) -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular, in: .rect(cornerRadius: cornerRadius, style: .continuous))
        } else {
            background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.08), radius: 15, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.6), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
    }
}

extension View {
    func toasts(_ toasts: Binding<[Toast]>) -> some View {
        self.modifier(ToastModifier(toasts: toasts))
    }
}
