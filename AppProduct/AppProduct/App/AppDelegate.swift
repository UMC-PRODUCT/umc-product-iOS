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
import SwiftData

/// Firebase 푸시 알림 및 FCM 토큰 관리를 담당하는 AppDelegate
///
/// 앱 생명주기에 따라 FCM 토큰 동기화, 푸시 알림 수신/저장,
/// 원격 알림 등록 등을 처리합니다.
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    // MARK: - Property

    private(set) var container: DIContainer!
    private(set) var modelContext: ModelContext?
    private var lastFailedFCMUpload: (memberId: Int, token: String)?

    // MARK: - Function

    /// GoogleService-Info.plist가 유효한 경우에만 Firebase를 초기화합니다.
    ///
    /// placeholder 값(`__FILL_IN__`)이 남아 있거나 이미 초기화된 경우 건너뜁니다.
    private func configureFirebaseIfNeeded() {
        guard FirebaseApp.app() == nil else { return }
        guard let plistPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plistData = NSDictionary(contentsOfFile: plistPath),
              let googleAppID = plistData["GOOGLE_APP_ID"] as? String,
              !googleAppID.isEmpty,
              !googleAppID.hasPrefix("__")
        else {
            print("[Firebase] GoogleService-Info.plist missing or contains placeholder values. Skipping configure.")
            return
        }
        FirebaseApp.configure()
    }

    /// DIContainer와 ModelContext를 설정하고 FCM 토큰 동기화를 시도합니다.
    ///
    /// - Parameters:
    ///   - container: 의존성 주입 컨테이너
    ///   - modelContext: SwiftData 모델 컨텍스트 (푸시 히스토리 저장용)
    func configure(container: DIContainer, modelContext: ModelContext) {
        self.container = container
        self.modelContext = modelContext
        Task { @MainActor in
            await self.syncFCMTokenIfPossible(trigger: "configure")
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        configureFirebaseIfNeeded()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        registerRemoteNotificationsIfAuthorized()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(memberProfileDidUpdate(_:)),
            name: .memberProfileUpdated,
            object: nil
        )
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        Task { @MainActor in
            await syncFCMTokenIfPossible(trigger: "didBecomeActive")
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02x", $0)}.joined()

        Messaging.messaging().apnsToken = deviceToken
        NotificationCenter.default.post(name: .deviceTokenReceived, object: tokenString)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {}
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        saveNoticeHistory(from: notification.request.content)
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        saveNoticeHistory(from: response.notification.request.content)
        completionHandler()
    }
}

// MARK: - MessagingDelegate

extension AppDelegate: MessagingDelegate {
    /// FCM 토큰이 갱신되면 UserDefaults에 저장하고 서버 동기화를 시도합니다.
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }

        let storedFcmToken = UserDefaults.standard.string(forKey: AppStorageKey.userFCMToken) ?? ""
        
        if storedFcmToken != fcmToken {
            UserDefaults.standard.set(fcmToken, forKey: AppStorageKey.userFCMToken)
            NotificationCenter.default.post(name: .fcmTokenReceived, object: fcmToken)
            Task { @MainActor in
                await syncFCMTokenIfPossible(trigger: "messagingDelegate")
            }
        }
    }
}

// MARK: - Notification.Name

extension Notification.Name {
    /// APNs 디바이스 토큰 수신 알림
    static let deviceTokenReceived = Notification.Name("deviceTokenReceived")
    /// FCM 토큰 수신/갱신 알림
    static let fcmTokenReceived = Notification.Name("fcmTokenReceived")
    /// 멤버 프로필 업데이트 알림 (FCM 토큰 재동기화 트리거)
    static let memberProfileUpdated = Notification.Name("memberProfileUpdated")
}

// MARK: - Private Function

private extension AppDelegate {
    @objc
    func memberProfileDidUpdate(_ notification: Notification) {
        Task { @MainActor in
            await syncFCMTokenIfPossible(trigger: "memberProfileUpdated")
        }
    }

    /// FCM 토큰을 서버에 동기화합니다.
    ///
    /// fcmToken이 존재하고,
    /// 이전에 업로드한 토큰/멤버ID 조합과 다를 때만 서버에 등록합니다.
    ///
    /// - Parameter trigger: 동기화를 트리거한 이벤트 이름 (디버그 로그용)
    @MainActor
    func syncFCMTokenIfPossible(trigger: String) async {
        guard let container else { return }
        let memberId = UserDefaults.standard.integer(forKey: AppStorageKey.memberId)
        let fcmToken = UserDefaults.standard.string(forKey: AppStorageKey.userFCMToken) ?? ""
        guard memberId != 0, !fcmToken.isEmpty else { return }

        if let lastFailed = lastFailedFCMUpload,
           lastFailed.memberId == memberId,
           lastFailed.token == fcmToken {
            return
        }

        let uploadedToken = UserDefaults.standard.string(forKey: AppStorageKey.uploadedFCMToken) ?? ""
        let uploadedMemberId = UserDefaults.standard.integer(forKey: AppStorageKey.uploadedFCMMemberId)
        guard uploadedToken != fcmToken || uploadedMemberId != memberId else { return }

        do {
            let provider = container.resolve(HomeUseCaseProviding.self)
            try await provider.registerFCMTokenUseCase.execute(
                fcmToken: fcmToken
            )
            lastFailedFCMUpload = nil
            UserDefaults.standard.set(fcmToken, forKey: AppStorageKey.uploadedFCMToken)
            UserDefaults.standard.set(memberId, forKey: AppStorageKey.uploadedFCMMemberId)
        } catch {
            lastFailedFCMUpload = (memberId: memberId, token: fcmToken)
        }
    }

    /// 수신된 푸시 알림 내용을 SwiftData에 저장합니다.
    ///
    /// - Parameter content: 푸시 알림 콘텐츠 (title, body, userInfo 추출)
    func saveNoticeHistory(from content: UNNotificationContent) {
        guard let modelContext else { return }
        let userInfo = content.userInfo
        let title = content.title.isEmpty
            ? (userInfo["title"] as? String ?? "알림")
            : content.title
        let body = content.body.isEmpty
            ? (userInfo["body"] as? String ?? userInfo["message"] as? String ?? "")
            : content.body

        let notice = NoticeHistoryData(
            title: title,
            content: body,
            createdAt: .now
        )
        modelContext.insert(notice)
        try? modelContext.save()
    }

    /// 푸시 알림 권한 상태를 확인하고, 허용 시 원격 알림을 등록합니다.
    ///
    /// - Note: 권한이 미결정(notDetermined) 상태이면 권한 요청을 먼저 수행합니다.
    func registerRemoteNotificationsIfAuthorized() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(
                    options: [.alert, .badge, .sound]
                ) { granted, _ in
                    guard granted else { return }
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            default:
                break
            }
        }
    }
}
