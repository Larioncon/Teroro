import SwiftUI
import UIKit


struct SwipeBackGestureModifier: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .background(Representable())
    }
    
    // MARK: - Private Representable
    
    private struct Representable: UIViewControllerRepresentable {
        
        func makeUIViewController(context: Context) -> UIViewController {
            ViewController()
        }
        
        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
            enableSwipeBack(from: uiViewController)
        }
        
        private func enableSwipeBack(from viewController: UIViewController) {
            DispatchQueue.main.async {
                let gestureRecognizer = viewController.navigationController?.interactivePopGestureRecognizer
                gestureRecognizer?.isEnabled = true
                gestureRecognizer?.delegate = nil
            }
        }
        
        private final class ViewController: UIViewController {
            override func viewDidAppear(_ animated: Bool) {
                super.viewDidAppear(animated)
                
                let gestureRecognizer = navigationController?.interactivePopGestureRecognizer
                gestureRecognizer?.isEnabled = true
                gestureRecognizer?.delegate = nil
            }
        }
    }
}

// MARK: - Convenience Extension

extension View {
    func swipeBackGestureEnabled() -> some View {
        modifier(SwipeBackGestureModifier())
    }
}
