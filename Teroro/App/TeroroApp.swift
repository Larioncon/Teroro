import SwiftUI

@main
struct TeroroApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var appState = AppState()
    
    init() {
        TabBarStyling.apply()
    }

    var body: some Scene {
        WindowGroup {
            SplashRootView(persistenceController: persistenceController)
                .environmentObject(appState)
        }
    }
}
