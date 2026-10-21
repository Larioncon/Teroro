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
            navigateToNextStep()
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

//    func requestAppReview() {
//        if let scene = UIApplication.shared.connectedScenes
//            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
//            SKStoreReviewController.requestReview(in: scene)
//        }
//        navigateToNextStep()
//    }

    func makeSeenOnb() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
    }
    
    func finishOnboarding(appState: AppState) {
        makeSeenOnb()
        if !SubscriptionService.shared.isPremium, NetworkMonitor.shared.isConnected {
            navigationRouter?.push(.onboardingPaywall)
        } else {
            navigationRouter?.popToRoot()
        }
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
            title: "onboarding.step1.title",
            subtitle: "onboarding.step1.subtitle"
        ),
        .init(
            img: "bell.badge",
            title: "onboarding.step2.title",
            subtitle: "onboarding.step2.subtitle"
        ),
        .init(
            img: "star.bubble",
            title: "onboarding.step3.title",
            subtitle: "onboarding.step3.subtitle"
        ),
        .init(
            img: "map",
            title: "onboarding.step4.title",
            subtitle: "onboarding.step4.subtitle"
        ),
        .init(
            img: "timer",
            title: "onboarding.step5.title",
            subtitle: "onboarding.step5.subtitle"
        )
    ]
}
