import SwiftUI
import UIKit

/// Configures the hosting navigation item so the system back button shows only its chevron.
struct MinimalBackButtonConfigurator: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ viewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            var candidate: UIViewController? = viewController

            while let current = candidate {
                if let navigationController = current.navigationController,
                   navigationController.viewControllers.contains(where: { $0 === current }) {
                    current.navigationItem.backButtonDisplayMode = .minimal
                    return
                }

                candidate = current.parent
            }
        }
    }
}
