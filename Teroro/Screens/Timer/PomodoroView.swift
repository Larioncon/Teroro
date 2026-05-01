import SwiftUI

struct PomodoroView: View {
    @ObservedObject var viewModel: PomodoroVM

    private let presets = [5, 10, 15, 25, 30, 45, 60]

    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 10) {
                Text(viewModel.timeText)
                    .font(.system(size: 56, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .padding(.top, 8)

                Text(viewModel.isRunning ? "Працює" : "Пауза")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Тривалість")
                    .font(.headline)

                Picker("Тривалість", selection: $viewModel.selectedMinutes) {
                    ForEach(presets, id: \.self) { m in
                        Text("\(m) хв").tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(viewModel.isRunning)
                .onChange(of: viewModel.selectedMinutes) { _ in
                    viewModel.applySelectedDuration()
                }

                Stepper(value: $viewModel.selectedMinutes, in: 1...180, step: 1) {
                    Text("Користувацька: \(viewModel.selectedMinutes) хв")
                        .foregroundStyle(.secondary)
                }
                .disabled(viewModel.isRunning)
                .onChange(of: viewModel.selectedMinutes) { _ in
                    viewModel.applySelectedDuration()
                }
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            HStack(spacing: 14) {
                Button {
                    viewModel.reset()
                } label: {
                    Text("Скинути")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    viewModel.toggle()
                } label: {
                    Text(viewModel.isRunning ? "Пауза" : "Старт")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .navigationTitle("Таймер")
        .onAppear {
            viewModel.applySelectedDuration()
        }
    }
}

#Preview {
    NavigationStack {
        PomodoroView(viewModel: PomodoroVM())
    }
}

