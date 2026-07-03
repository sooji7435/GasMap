import UIKit
import GoogleMobileAds

extension Notification.Name {
    static let mobileAdsReady = Notification.Name("MobileAdsReady")
}

class AppDelegate: NSObject, UIApplicationDelegate {
    static var isMobileAdsReady = false

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        MobileAds.shared.start { _ in
            AppDelegate.isMobileAdsReady = true
            NotificationCenter.default.post(name: .mobileAdsReady, object: nil)
        }
        return true
    }
}
