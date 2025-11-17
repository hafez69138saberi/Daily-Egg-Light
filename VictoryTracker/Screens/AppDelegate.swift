import UIKit
import Firebase
import FirebaseMessaging
import AppsFlyerLib
import AppTrackingTransparency


enum MyConstants {
    static let webUserAgent =
      "Mozilla/5.0 (iPhone; CPU iPhone OS 17_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Mobile/15E148 Safari/604.1"

    static let udidKey = "device_uuid_lower"
    static let finalURLCacheKey = "cached_final_url"
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
      
        
         UNUserNotificationCenter.current().delegate = self
         UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
             DispatchQueue.main.async {
                 UIApplication.shared.registerForRemoteNotifications()
                 
                 DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                     self.requestTrackingAuthorization()
                       }
             }
         }
         Messaging.messaging().delegate = TokenStore.shared
         
        
        TokenStore.shared.start()
        
        AppsFlyerLib.shared().appsFlyerDevKey = "P8Cmc5f5JjkNjQ3haoGbWS"
        AppsFlyerLib.shared().appleAppID     = "6754684475"
        AppsFlyerLib.shared().delegate       = self
        
        AppsFlyerLib.shared().start()
        
        let uuid = DeviceIDProvider.persistedLowerUUID()
        let att = AdServicesTokenProvider.fetchBase64Token()
        
        FirebaseLogger.logSession(uuid: uuid, attToken: att)
        
        StartGateService.shared.configureSession(uuid: uuid, attToken: att)
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = LaunchViewController()
        window?.makeKeyAndVisible()
        return true
    }
 
    
    private func requestTrackingAuthorization() {
            if #available(iOS 14, *) {
                ATTrackingManager.requestTrackingAuthorization { status in
                    switch status {
                    case .authorized:
                        print("")
                    case .denied:
                        print("")
                    case .restricted:
                        print("")
                    case .notDetermined:
                        print("")
                    @unknown default:
                        break
                    }
                }
            } else {
                print("")
            }
        }
    
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        let m = OrientationManager.shared.mask
        return m
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
}

final class OrientationManager {
    static let shared = OrientationManager()
    private init() {}
    
    var mask: UIInterfaceOrientationMask = .all
}

extension AppDelegate: MessagingDelegate, UNUserNotificationCenterDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    }
}

extension AppDelegate: AppsFlyerLibDelegate {
    func onConversionDataSuccess(_ conversionInfo: [AnyHashable : Any]) {
    }
    func onConversionDataFail(_ error: Error) {
    }
}

enum DeviceIDProvider {
    static func persistedLowerUUID() -> String {
        if let v = UserDefaults.standard.string(forKey: MyConstants.udidKey) { return v }
        let u = UUID().uuidString.lowercased()
        UserDefaults.standard.set(u, forKey: MyConstants.udidKey)
        return u
    }
}
