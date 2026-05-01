import Foundation
import Combine

@MainActor
final class PomodoroVM: ObservableObject {
    @Published var selectedMinutes: Int = 25
    @Published private(set) var remainingSeconds: Int = 25 * 60
    @Published private(set) var isRunning: Bool = false

    private var ticker: AnyCancellable?
    private var endDate: Date?

    func applySelectedDuration() {
        guard !isRunning else { return }
        remainingSeconds = max(1, selectedMinutes) * 60
    }

    func toggle() {
        isRunning ? pause() : start()
    }

    func reset() {
        pause()
        remainingSeconds = max(1, selectedMinutes) * 60
    }

    private func start() {
        guard !isRunning else { return }
        isRunning = true
        endDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))

        ticker = Timer.publish(every: 0.25, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func pause() {
        isRunning = false
        ticker?.cancel()
        ticker = nil
        endDate = nil
    }

    private func tick() {
        guard let endDate else { return }
        let newValue = max(0, Int(endDate.timeIntervalSinceNow.rounded(.down)))
        if newValue != remainingSeconds {
            remainingSeconds = newValue
        }
        if remainingSeconds <= 0 {
            reset()
        }
    }

    var timeText: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

