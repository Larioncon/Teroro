import SwiftUI

struct PomodoroButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(color)
            .frame(width: 110, height: 110)
            .background(.ultraThinMaterial, in: Circle())
            .overlay {
                Circle()
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        }
    }
}

#Preview {
    HStack {
        PomodoroButton(title: "СТАРТ", icon: "play.fill", color: .primary) {}
        PomodoroButton(title: "СТОП", icon: "stop.fill", color: .primary) {}
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
