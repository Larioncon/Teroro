import SwiftUI

struct PomodoroView: View {
    @ObservedObject var viewModel: PomodoroVM
    @State private var isShowingPicker = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
           
            VStack(spacing: adaptiveSpacing) {
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
                    
                    Text(viewModel.mode == .focus ? "FOCUS TIME" : "RELAX")
                        .font(.system(size: 14, weight: .black))
                        .kerning(2)
                        .foregroundStyle(viewModel.mode == .focus ? Color.secondary : Color.green)
                        .padding(.top, 4)

                    if viewModel.notificationStatus == .denied {
                        Button(action: {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "bell.slash.fill")
                                Text("Сповіщення вимкнено")
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.red)
                            .padding(.top, 4)
                        }
                    }
                }
                .padding(.top, 40)

                // Central Timer Widget
                ZStack {

                    // 1. Glass Ring with Wave Animation
                    TimelineView(.animation) { timeline in
                        let phase = timeline.date.timeIntervalSince1970 * 2
                        
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay {
                                    Wave(phase: phase, progress: viewModel.progress)
                                        .fill((viewModel.mode == .focus ? Color.red : Color.green).opacity(0.4))
                                        .clipShape(Circle())
                                }
                                .overlay {
                                    Circle()
                                        .stroke(Color.primary.opacity(0.1), lineWidth: 1.5)
                                }
                        }
                        .frame(width: 260, height: 260)
                    }

                    // 3. Tomato/Cucumber Asset with Flip Animation
                    ZStack {
                        Image(.tomato)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 220, height: 220)
                            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                            .opacity(viewModel.mode == .focus ? 1 : 0)
                            .rotation3DEffect(
                                .degrees(viewModel.mode == .focus ? 0 : 180),
                                axis: (x: 0, y: 1, z: 0)
                            )

                        Image(.cucumber)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 180)
                            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                            .opacity(viewModel.mode == .rest ? 1 : 0)
                            .rotation3DEffect(
                                .degrees(viewModel.mode == .rest ? 0 : -180),
                                axis: (x: 0, y: 1, z: 0)
                            )
                    }
                }


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
                        title: viewModel.mode == .focus ? "СТОП" : "ЗАВЕРШИТИ",
                        icon: "stop.fill",
                        color: .primary
                    ) {
                        viewModel.stop()
                    }
                }
                .padding(.top, adaptivePaddingTop)

                
                Spacer()
            }

            // Time Picker Overlay
            if isShowingPicker {
                // Dimming Background
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            isShowingPicker = false
                        }
                    }
                    .zIndex(1)

                // Card Content
                VStack(spacing: 30) {
                    Text("Тривалість")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    HorizontalRulerPicker(selection: $viewModel.selectedMinutes)

                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
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
                .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .center)))
                .zIndex(2)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .animation(.spring(), value: viewModel.isRunning)
        .animation(.spring(), value: viewModel.mode)
        .toolbar(viewModel.isRunning ? .hidden : .visible, for: .tabBar)
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                viewModel.refreshNotificationStatus()
            }
        }
    }

    private var timerText: some View {
        Text(viewModel.timeText)
            .font(.system(size: 64, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.primary)
    }
}

#Preview {
    PomodoroView(viewModel: PomodoroVM())
}
