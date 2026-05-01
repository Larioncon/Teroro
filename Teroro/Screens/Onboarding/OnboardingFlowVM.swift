import SwiftUI
import UserNotifications
import AppTrackingTransparency
import StoreKit
import UIKit

@MainActor
final class OnboardingFlowVM: ObservableObject {
   
    @Published var currentStep: Int = 0
    
    weak var navigationRouter: AppRouter?
    weak var appState: AppState?
    
    let steps: [OnboardingStep]

    var shouldShowOnboarding: Bool {
        !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    }

    init(currentStep: Int = 0, navigationRouter: AppRouter? = nil, steps: [OnboardingStep] = OnboardingStep.defaults) {
        self.currentStep = currentStep
        self.navigationRouter = navigationRouter
        self.steps = steps
    }

    var isLastStep: Bool {
        currentStep >= steps.count - 1
    }

    var canNavigateNext: Bool {
        currentStep < steps.count - 1
    }

    var currentStepData: OnboardingStep {
        steps[currentStep]
    }

    func handlePrimaryButtonTap(appState: AppState) {
        switch currentStep {
        case 0:
            navigateToNextStep()
        case 1:
            navigateToNextStep()
        case 2:
            requestAppReview()
        case 3:
            navigateToNextStep()
        case 4:
            finishOnboarding(appState: appState)
        default:
            break
        }
    }

    func onStepChanged(to step: Int) {
        guard step == 0 else { return }
        makeSeenOnb()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
//            self.requestNotificationAndTrackingPermissions()
            self.requestTrackingPermission()
        }
    }

//    func requestNotificationAndTrackingPermissions() {
//        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
//            if let error = error {
//                self.appState?.showErrorAlert(error.localizedDescription)
//            }
//            
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
//                self.requestTrackingPermission()
//            }
//        }
//    }

    func requestTrackingPermission() {
        Task {
            _ = await ATTrackingManager.requestTrackingAuthorization()
        }
    }

    func requestAppReview() {
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
        navigateToNextStep()
    }

    func makeSeenOnb() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
    }
    
    func finishOnboarding(appState: AppState) {
        makeSeenOnb()
        navigationRouter?.popToRoot()
    }

    private func navigateToNextStep() {
        guard canNavigateNext else { return }
        currentStep += 1
    }
}

struct OnboardingStep: Identifiable, Hashable {
    let id = UUID()
    let img: String
    let title: String
    let subtitle: String
}

extension OnboardingStep {
    static let defaults: [OnboardingStep] = [
        .init(
            img: "sparkles",
            title: "Терміни під контролем",
            subtitle: "Додавайте терміни з датою, часом та нагадуваннями."
        ),
        .init(
            img: "bell.badge",
            title: "Нагадування вчасно",
            subtitle: "Дозвольте сповіщення, щоб не пропустити важливе."
        ),
        .init(
            img: "star.bubble",
            title: "Швидко звикнете",
            subtitle: "Якщо подобається — залиште короткий відгук."
        ),
        .init(
            img: "map",
            title: "На мапі — зручно",
            subtitle: "Переглядайте терміни на мапі (локації налаштуємо пізніше)."
        ),
        .init(
            img: "timer",
            title: "Фокус із таймером",
            subtitle: "Запускайте Pomodoro, щоб тримати темп і не вигоріти."
        )
    ]
}
