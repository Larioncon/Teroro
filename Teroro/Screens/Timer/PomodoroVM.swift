import Foundation
import Combine
import SwiftUI

enum PomodoroMode: String {
    case focus
    case rest
}

@MainActor
final class PomodoroVM: ObservableObject {
    @AppStorage("pomodoroSelectedMinutes") var selectedMinutes: Int = 25 {
        didSet {
            applySelectedDuration()
        }
    }
    

    @AppStorage("pomodoroIsRunning") private var persistedIsRunning: Bool = false
    @AppStorage("pomodoroMode") private var persistedMode: String = PomodoroMode.focus.rawValue
    @AppStorage("pomodoroEndDate") private var persistedEndDate: Double = 0
    @AppStorage("pomodoroRemainingSeconds") private var persistedRemainingSeconds: Int = 25 * 60

    @Published private(set) var remainingSeconds: Int = 25 * 60
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var mode: PomodoroMode = .focus
    @Published private(set) var notificationStatus: UNAuthorizationStatus = .notDetermined
    
    // Progress for the wave effect (0.0 to 1.0)
    var progress: Double {
        let total = Double((mode == .focus ? max(1, selectedMinutes) : 5) * 60)
        let raw = 1.0 - (Double(remainingSeconds) / total)
        // If focus: 0 -> 1 (filling up). If rest: 1 -> 0 (draining).
        return mode == .focus ? raw : (1.0 - raw)
    }

    private var ticker: AnyCancellable?
    private var endDate: Date?

    init() {
        // Restore state
        let mode = PomodoroMode(rawValue: persistedMode) ?? .focus
        self.mode = mode
        
        if persistedIsRunning {
            let endDate = Date(timeIntervalSince1970: persistedEndDate)
            let diff = Int(endDate.timeIntervalSinceNow.rounded(.up))
            
            if diff > 0 {
                self.remainingSeconds = diff
                self.endDate = endDate
                self.isRunning = true
                startTicker()
            } else {
                // Timer finished while app was closed
                self.isRunning = false
                self.persistedIsRunning = false
                if mode == .focus {
                    self.mode = .rest
                    self.remainingSeconds = 5 * 60
                } else {
                    self.mode = .focus
                    self.remainingSeconds = max(1, selectedMinutes) * 60
                }
                self.persistedMode = self.mode.rawValue
                self.persistedRemainingSeconds = self.remainingSeconds
            }
        } else {
            self.remainingSeconds = persistedRemainingSeconds
        }
        
        refreshNotificationStatus()
    }

    func refreshNotificationStatus() {
        Task {
            let status = await NotificationService.shared.authorizationStatus()
            self.notificationStatus = status
        }
    }

    func applySelectedDuration() {
        guard !isRunning, mode == .focus else { return }
        remainingSeconds = max(1, selectedMinutes) * 60
        persistedRemainingSeconds = remainingSeconds
        objectWillChange.send()
    }

    func toggle() {
        isRunning ? pause(isManual: true) : start()
    }

    func reset() {
        pause(isManual: true)
        mode = .focus
        remainingSeconds = max(1, selectedMinutes) * 60
        persistedMode = mode.rawValue
        persistedRemainingSeconds = remainingSeconds
    }

    private func start() {
        guard !isRunning else { return }
        isRunning = true
        endDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        
        // Save persistence
        persistedIsRunning = true
        persistedEndDate = endDate?.timeIntervalSince1970 ?? 0
        persistedMode = mode.rawValue

        startTicker()

        Task {
            await NotificationService.shared.requestAuthorizationIfNeeded()
            refreshNotificationStatus()
            if mode == .focus {
                await NotificationService.shared.schedulePomodoroNotification(after: remainingSeconds)
            } else {
                await NotificationService.shared.scheduleRestNotification(after: remainingSeconds)
            }
        }
    }
    
    private func startTicker() {
        ticker?.cancel()
        ticker = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func pause(isManual: Bool = false) {
        isRunning = false
        ticker?.cancel()
        ticker = nil
        endDate = nil
        
        persistedIsRunning = false
        persistedRemainingSeconds = remainingSeconds

        if isManual {
            Task {
                await NotificationService.shared.cancelPomodoroNotification()
            }
        }
    }

    func stop() {
        reset()
    }

    func sync() {
        guard isRunning, let endDate = endDate else { return }
        let newValue = max(0, Int(endDate.timeIntervalSinceNow.rounded(.up)))
        if newValue != remainingSeconds {
            remainingSeconds = newValue
        }
        if remainingSeconds <= 0 {
            tick() // Trigger completion logic
        }
    }

    private func tick() {
        guard let endDate else { return }
        let newValue = max(0, Int(endDate.timeIntervalSinceNow.rounded(.up)))
        if newValue != remainingSeconds {
            remainingSeconds = newValue
        }
        if remainingSeconds <= 0 {
            pause(isManual: false)
            
            if mode == .focus {
                // Switch to rest mode, but wait for manual start
                mode = .rest
                remainingSeconds = 5 * 60
            } else {
                // Rest is over, back to focus
                mode = .focus
                remainingSeconds = max(1, selectedMinutes) * 60
            }
            
            // Save persistence for the new state
            persistedMode = mode.rawValue
            persistedRemainingSeconds = remainingSeconds
        }
    }

    var timeText: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}
