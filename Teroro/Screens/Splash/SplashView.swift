import SwiftUI

struct SplashView: View {
    @State private var animateIn = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.secondarySystemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Image("logopdf")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .scaleEffect(animateIn ? (pulse ? 1.04 : 1.0) : 0.82)
                    .opacity(animateIn ? 1 : 0)
                    .shadow(
                        color: Color.black.opacity(0.12),
                        radius: 18,
                        x: 0,
                        y: 10
                    )


            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                animateIn = true
            }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

#Preview {
    SplashView()
}

