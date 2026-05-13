import Foundation
import Combine
import SwiftUI

@MainActor
final class PomodoroVM: ObservableObject {
    @AppStorage("pomodoroSelectedMinutes") var selectedMinutes: Int = 25 {
        didSet {
            applySelectedDuration()
        }
    }
    @Published private(set) var remainingSeconds: Int = 25 * 60
    @Published private(set) var isRunning: Bool = false
    
    // Progress for the wave effect (0.0 to 1.0)
    var progress: Double {
        let total = Double(max(1, selectedMinutes) * 60)
        return 1.0 - (Double(remainingSeconds) / total)
    }

    private var ticker: AnyCancellable?
    private var endDate: Date?

    init() {
        // Initialize remainingSeconds with the persisted value
        _remainingSeconds = Published(initialValue: max(1, selectedMinutes) * 60)
    }

    func applySelectedDuration() {
        guard !isRunning else { return }
        remainingSeconds = max(1, selectedMinutes) * 60
        objectWillChange.send()
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

        ticker = Timer.publish(every: 0.1, on: .main, in: .common)
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

    func stop() {
        reset()
    }

    private func tick() {
        guard let endDate else { return }
        let newValue = max(0, Int(endDate.timeIntervalSinceNow.rounded(.up)))
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
