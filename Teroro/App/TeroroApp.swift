import SwiftUI
import FirebaseCore
import GoogleSignIn


@main
struct TeroroApp: App {
  let persistenceController = PersistenceController.shared
  @StateObject private var appState = AppState()
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
class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        
        // MARK: - RevenueCat init
//        Purchases.configure(withAPIKey: AppConstants.revenueCatKey)
//        
//        Purchases.logLevel = .verbose
        
        // MARK: AppsFlyer init
//        AppsFlyerLib.shared().appsFlyerDevKey = AppConstants.appsflyerKey
//        AppsFlyerLib.shared().appleAppID = AppConstants.appleID
        
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
    
//    func applicationDidBecomeActive(_ application: UIApplication) {
//        AppsFlyerLib.shared().start()
//    }
//    
//    @objc private func sendLaunch() {
//        AppsFlyerLib.shared().start()
//    }
    
}
