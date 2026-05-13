import SwiftUI

struct PomodoroView: View {
    @ObservedObject var viewModel: PomodoroVM
    @State private var isShowingPicker = false

    var body: some View {
        ZStack {
           
            VStack(spacing: 40) {
                // Header
                VStack(spacing: 4) {
                    Button(action: {
                        if !viewModel.isRunning {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isShowingPicker = true
                            }
                        }
                    }) {
                        timerText
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isRunning)
                    
                    Text("FOCUS TIME")
                        .font(.system(size: 14, weight: .black))
                        .kerning(2)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                .padding(.top, 40)

                // Central Timer Widget
                ZStack {
                    // 1. Soft Radial Glow
//                    RadialGradient(
//                        colors: [.red.opacity(0.15), .clear],
//                        center: .center,
//                        startRadius: 0,
//                        endRadius: 150
//                    )
//                    .frame(width: 300, height: 300)

                    // 2. Glass Ring with Wave Animation
                    TimelineView(.animation) { timeline in
                        let phase = timeline.date.timeIntervalSince1970 * 2
                        
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay {
                                    Wave(phase: phase, progress: viewModel.progress)
                                        .fill(Color.red.opacity(0.4))
                                        .clipShape(Circle())
                                }
                                .overlay {
                                    Circle()
                                        .stroke(Color.primary.opacity(0.1), lineWidth: 1.5)
                                }
                        }
                        .frame(width: 260, height: 260)
                    }

                    // 3. Tomato Asset (Always on top)
                    Image("tomato")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220, height: 220)
                        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                }

                Spacer()

                // Action Buttons
                HStack(spacing: 30) {
                    PomodoroButton(
                        title: viewModel.isRunning ? "ПАУЗА" : "СТАРТ",
                        icon: viewModel.isRunning ? "pause.fill" : "play.fill",
                        color: .primary
                    ) {
                        viewModel.toggle()
                    }

                    PomodoroButton(
                        title: "СТОП",
                        icon: "stop.fill",
                        color: .primary
                    ) {
                        viewModel.stop()
                    }
                }
                .padding(.bottom, 50)
            }

            // Time Picker Overlay
            if isShowingPicker {
                pickerOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .navigationBarHidden(true)
    }

    private var timerText: some View {
        Text(viewModel.timeText)
            .font(.system(size: 64, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.primary)
    }

    private var pickerOverlay: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring()) {
                        isShowingPicker = false
                    }
                }

            VStack(spacing: 30) {
                Text("Тривалість")
                    .font(.headline)
                    .foregroundStyle(.primary)

                HorizontalRulerPicker(selection: $viewModel.selectedMinutes)

                Button(action: {
                    withAnimation(.spring()) {
                        isShowingPicker = false
                    }
                }) {
                    Text("Готово")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(Color.accentColor, in: Capsule())
                }
            }
            .padding(.vertical, 40)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30))
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Horizontal Ruler Picker (with Haptics and Center Selection)
struct HorizontalRulerPicker: View {
    @Binding var selection: Int
    private let values = Array(stride(from: 5, through: 120, by: 5))
    private let impact = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        ZStack {
            // Visual Center Indicator
            Rectangle()
                .fill(Color.accentColor)
                .frame(width: 2, height: 60)
                .offset(y: 10)
                .zIndex(1)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 35) {
                        ForEach(values, id: \.self) { val in
                            GeometryReader { itemGeo in
                                let midX = itemGeo.frame(in: .global).midX
                                let screenMidX = UIScreen.main.bounds.width / 2
                                let distance = abs(midX - screenMidX)
                                
                                VStack(spacing: 12) {
                                    Text("\(val)")
                                        .font(.system(size: 22, weight: .bold))
                                        .scaleEffect(distance < 20 ? 1.2 : 1.0)
                                    
                                    Rectangle()
                                        .fill(distance < 20 ? Color.accentColor : Color.primary.opacity(0.2))
                                        .frame(width: 2, height: distance < 20 ? 45 : 30)
                                }
                                .foregroundStyle(distance < 20 ? Color.primary : Color.secondary)
                                .onChange(of: midX) { _ in
                                    if distance < 20 && selection != val {
                                        selection = val
                                        impact.impactOccurred()
                                    }
                                }
                            }
                            .frame(width: 40)
                            .id(val)
                        }
                    }
                    .padding(.horizontal, UIScreen.main.bounds.width / 2 - 20)
                }
                .frame(height: 100)
                .onAppear {
                    impact.prepare()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        proxy.scrollTo(selection, anchor: .center)
                    }
                }
            }
        }
    }
}

// MARK: - Wave Shape
struct Wave: Shape {
    var phase: Double
    var progress: Double
    
    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let progressHeight = height * (1 - progress)
        let waveHeight: CGFloat = 10
        
        path.move(to: CGPoint(x: 0, y: progressHeight))
        
        for x in stride(from: 0, to: width, by: 1) {
            let relativeX = x / width
            let sine = sin(relativeX * .pi * 2 + phase)
            let y = progressHeight + CGFloat(sine) * waveHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Pomodoro Button
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
    PomodoroView(viewModel: PomodoroVM())
}
