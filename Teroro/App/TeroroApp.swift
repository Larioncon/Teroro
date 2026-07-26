import SwiftUI
import RevenueCat
import FirebaseCore
import GoogleSignIn
import UserNotifications


@main
struct TeroroApp: App {
  let persistenceController = PersistenceController.shared
  @StateObject private var appState = AppState.shared
  @UIApplicationDelegateAdaptor(AppDelegate.self) private var firebaseDelegate
    
    init() {
        TabBarStyling.apply()
        // MARK: - FIREBASE INIT
        FirebaseApp.configure()
    }

  var body: some Scene {
    WindowGroup {
      SplashRootView(persistenceController: persistenceController)
        .environmentObject(appState)
    }
  }
}

// MARK: AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        UNUserNotificationCenter.current().delegate = self
        
        
        // MARK: - RevenueCat init
        Purchases.configure(withAPIKey: AppConstants.revenueCatKey)
        Purchases.logLevel = .verbose
        
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(sendLaunch),
//            name: UIApplication.didBecomeActiveNotification,
//            object: nil
//        )
        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
    
    
}
