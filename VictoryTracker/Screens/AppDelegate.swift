import UIKit
import Firebase
import FirebaseMessaging
import AppsFlyerLib
import AppTrackingTransparency


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
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        
        AppsFlyerLib.shared().appsFlyerDevKey = "P8Cmc5f5JjkNjQ3haoGbWS"
        AppsFlyerLib.shared().appleAppID = "6754684475"
        AppsFlyerLib.shared().delegate = self
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
    
    private func requestATTAndStartSDKs() {
        guard #available(iOS 14.5, *) else {
            startSDKsWithCurrentPrivacyState()
            return
        }

        ATTrackingManager.requestTrackingAuthorization { status in
            DispatchQueue.main.async {
                self.startSDKsWithCurrentPrivacyState()
            }
        }
    }

    private func startSDKsWithCurrentPrivacyState() {
        if #available(iOS 14.5, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus
            switch status {
            case .authorized:
                print("")
            default:
                print("")
            }
        }

        AppsFlyerLib.shared().start()
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
