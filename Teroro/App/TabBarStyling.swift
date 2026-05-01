import UIKit

enum TabBarStyling {
    static func apply() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()

        if #available(iOS 26.0, *) {
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
            appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.12)
            appearance.shadowColor = UIColor.clear
        } else {
            appearance.backgroundEffect = nil
            appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.72)
            appearance.shadowColor = UIColor.separator.withAlphaComponent(0.25)
        }

        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.isTranslucent = true
    }
}
