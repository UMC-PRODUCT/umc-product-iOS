//
//  AppDelegate.swift
//  AppProduct
//
//  Created by euijjang97 on 1/10/26.
//

import Foundation
import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    private(set) var container: DIContainer!
    
    func configure(container: DIContainer) {
        self.container = container
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02x", $0)}.joined()
        
        #if DEBUG
        print("디바이스 토큰: \(tokenString)")
        #endif
        
        Messaging.messaging().apnsToken = deviceToken
        NotificationCenter.default.post(name: .deviceTokenReceived, object: tokenString)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        print("Failed to register: \(error.localizedDescription)")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("포그라운드에서 푸시 수신: \(notification.request.content.userInfo)")
        completionHandler([.banner, .sound, .badge])
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        
        #if DEBUG
        print("APNs를 위한 디바이스 토큰: \(fcmToken)")
        #endif
        
        let storedFcmToken = UserDefaults.standard.string(forKey: AppStorageKey.userFCMToken) ?? ""
        
        if storedFcmToken != fcmToken {
            #if DEBUG
            print("FCM 토큰이 변경됨: \(storedFcmToken) → \(fcmToken)")
            #endif
            
            UserDefaults.standard.set(fcmToken, forKey: AppStorageKey.userFCMToken)
            // !!!: - FCM 토큰 서버 전달 로직 필요
        }
    }
}

extension Notification.Name {
    static let deviceTokenReceived = Notification.Name("deviceTokenReceived")
}
