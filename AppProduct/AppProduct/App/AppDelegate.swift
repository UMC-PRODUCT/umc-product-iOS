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
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        logDeviceIdentifiers()
        seedAPITestTokenIfNeeded()
        seedAppStorageProfileIfNeeded()
        seedAuthTokenFromEnvironmentIfNeeded()
        injectDebugTokensIfNeeded()
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
        
        #if DEBUG
        print("디바이스 토큰: \(tokenString)")
        #endif
        
        Messaging.messaging().apnsToken = deviceToken
        NotificationCenter.default.post(name: .deviceTokenReceived, object: tokenString)
        logCurrentFCMToken()
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        print("Failed to register: \(error.localizedDescription)")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("포그라운드에서 푸시 수신: \(notification.request.content.userInfo)")
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
        
        #if DEBUG
        print("FCM 토큰 수신: \(fcmToken)")
        #endif
        
        let storedFcmToken = UserDefaults.standard.string(forKey: AppStorageKey.userFCMToken) ?? ""
        
        if storedFcmToken != fcmToken {
            #if DEBUG
            print("FCM 토큰이 변경됨: \(storedFcmToken) → \(fcmToken)")
            #endif
            
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
        guard memberId != 0, !fcmToken.isEmpty else {
            #if DEBUG
            print("[FCM] skip upload (\(trigger)) memberId=\(memberId), tokenEmpty=\(fcmToken.isEmpty)")
            #endif
            return
        }

        if let lastFailed = lastFailedFCMUpload,
           lastFailed.memberId == memberId,
           lastFailed.token == fcmToken {
            #if DEBUG
            print("[FCM] skip upload (\(trigger)) last attempt failed for same member/token")
            #endif
            return
        }

        let uploadedToken = UserDefaults.standard.string(forKey: AppStorageKey.uploadedFCMToken) ?? ""
        let uploadedMemberId = UserDefaults.standard.integer(forKey: AppStorageKey.uploadedFCMMemberId)
        guard uploadedToken != fcmToken || uploadedMemberId != memberId else {
            #if DEBUG
            print("[FCM] already uploaded memberId=\(memberId)")
            #endif
            return
        }

        do {
            let provider = container.resolve(HomeUseCaseProviding.self)
            try await provider.registerFCMTokenUseCase.execute(
                fcmToken: fcmToken
            )
            lastFailedFCMUpload = nil
            UserDefaults.standard.set(fcmToken, forKey: AppStorageKey.uploadedFCMToken)
            UserDefaults.standard.set(memberId, forKey: AppStorageKey.uploadedFCMMemberId)
            #if DEBUG
            print("[FCM] upload success memberId=\(memberId)")
            #endif
        } catch {
            lastFailedFCMUpload = (memberId: memberId, token: fcmToken)
            #if DEBUG
            print("[FCM] upload failed: \(error)")
            #endif
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
        do {
            try modelContext.save()
            #if DEBUG
            print("[PushHistory] saved title=\(title)")
            #endif
        } catch {
            #if DEBUG
            print("[PushHistory] save failed: \(error)")
            #endif
        }
    }

    func logDeviceIdentifiers() {
        let vendorId = UIDevice.current.identifierForVendor?.uuidString ?? "nil"
        #if targetEnvironment(simulator)
        let simulatorUDID = ProcessInfo.processInfo.environment["SIMULATOR_UDID"] ?? "nil"
        print("[Device] simulatorUDID=\(simulatorUDID), identifierForVendor=\(vendorId)")
        #else
        print("[Device] identifierForVendor=\(vendorId)")
        #endif
    }

    func seedAPITestTokenIfNeeded() {
        #if DEBUG
        let environment = ProcessInfo.processInfo.environment
        guard let rawAccessToken = environment["UMC_API_TEST_ACCESS_TOKEN"] else { return }
        let accessToken = rawAccessToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !accessToken.isEmpty else { return }
        let refreshToken = accessToken

        Task {
            do {
                try await KeychainTokenStore().save(
                    accessToken: accessToken,
                    refreshToken: refreshToken
                )
                print("[Auth] Seeded API test access token from scheme environment.")
            } catch {
                print("[Auth] Failed to seed API test token: \(error)")
            }
        }
        #endif
    }

    /// HomeDebug 스킴 Pre-action이 생성한 토큰 파일을 읽어 Keychain에 직접 주입
    func injectDebugTokensIfNeeded() {
        #if DEBUG
        let path = "/tmp/umc_debug_tokens.json"
        guard let data = FileManager.default.contents(atPath: path),
              let json = try? JSONSerialization.jsonObject(with: data)
                  as? [String: Any],
              let access = json["accessToken"] as? String,
              !access.isEmpty,
              let refresh = json["refreshToken"] as? String,
              !refresh.isEmpty,
              let memberId = json["memberId"] as? Int
        else { return }

        writeToKeychain(key: "accessToken", value: access)
        writeToKeychain(key: "refreshToken", value: refresh)
        UserDefaults.standard.set(
            memberId,
            forKey: AppStorageKey.memberId
        )
        try? FileManager.default.removeItem(atPath: path)
        print("[DebugTokens] 주입 완료 (memberId: \(memberId))")
        #endif
    }

    func writeToKeychain(key: String, value: String) {
        let service = "com.ump.product"
        guard let data = value.data(using: .utf8) else { return }
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String:
                kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    func seedAppStorageProfileIfNeeded() {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        let hasLegacySeedFlag = args.contains("--seed-appstorage-dummy")
            || args.contains("--seed-appstorage-dummy-central")
            || args.contains("--seed-appstorage-dummy-chapter")
            || args.contains("--seed-appstorage-dummy-school")
            || args.contains("--seed-appstorage-dummy-challenger")
        let seededRoleFromArgument = parseSeededMemberRole(from: args)
        guard hasLegacySeedFlag || seededRoleFromArgument != nil
        else { return }
        let defaults = UserDefaults.standard

        let isCentralSeed = args.contains("--seed-appstorage-dummy-central")
        let isChapterSeed = args.contains("--seed-appstorage-dummy-chapter")
        let isSchoolSeed = args.contains("--seed-appstorage-dummy-school")
        let isChallengerSeed = args.contains("--seed-appstorage-dummy-challenger")
        let seededRole: ManagementTeam = seededRoleFromArgument ?? {
            if isCentralSeed { return .centralOperatingTeamMember }
            if isChallengerSeed { return .challenger }
            if isSchoolSeed { return .schoolPresident }
            if isChapterSeed { return .chapterPresident }
            return .centralOperatingTeamMember
        }()
        defaults.set(123, forKey: AppStorageKey.memberId)
        defaults.set(9, forKey: AppStorageKey.gisuId)
        defaults.set(5318, forKey: AppStorageKey.challengerId)
        defaults.set(9, forKey: AppStorageKey.schoolId)
        defaults.set("중앙대학교", forKey: AppStorageKey.schoolName)
        defaults.set(11, forKey: AppStorageKey.chapterId)
        defaults.set("Product", forKey: AppStorageKey.chapterName)
        defaults.set("ANDROID", forKey: AppStorageKey.responsiblePart)
        let seededOrganizationType = organizationType(for: seededRole)
        defaults.set(seededOrganizationType.rawValue, forKey: AppStorageKey.organizationType)
        defaults.set(11, forKey: AppStorageKey.organizationId)
        defaults.set(seededRole.rawValue, forKey: AppStorageKey.memberRole)

        let seededType = seededOrganizationType.rawValue
        print("[AppStorage] seeded dummy profile for scheme (\(seededType), role=\(seededRole.rawValue))")
        #endif
    }

    #if DEBUG
    /// 스킴 인자에서 공지 권한 검증용 `memberRole` 값을 파싱합니다.
    ///
    /// 지원 형식:
    /// - `-seed-member-role <ManagementTeam.rawValue>`
    /// - `--seed-appstorage-role-<kebab-case-role>`
    private func parseSeededMemberRole(from args: [String]) -> ManagementTeam? {
        if let index = args.firstIndex(of: "-seed-member-role"),
           args.indices.contains(index + 1),
           let role = ManagementTeam(rawValue: args[index + 1]) {
            return role
        }

        let roleFlags: [(flag: String, role: ManagementTeam)] = [
            ("--seed-appstorage-role-super-admin", .superAdmin),
            ("--seed-appstorage-role-central-president", .centralPresident),
            ("--seed-appstorage-role-central-vice-president", .centralVicePresident),
            ("--seed-appstorage-role-central-operating-team-member", .centralOperatingTeamMember),
            ("--seed-appstorage-role-central-education-team-member", .centralEducationTeamMember),
            ("--seed-appstorage-role-chapter-president", .chapterPresident),
            ("--seed-appstorage-role-school-president", .schoolPresident),
            ("--seed-appstorage-role-school-vice-president", .schoolVicePresident),
            ("--seed-appstorage-role-school-part-leader", .schoolPartLeader),
            ("--seed-appstorage-role-school-etc-admin", .schoolEtcAdmin),
            ("--seed-appstorage-role-challenger", .challenger)
        ]

        for roleFlag in roleFlags where args.contains(roleFlag.flag) {
            return roleFlag.role
        }
        return nil
    }

    /// 디버그 시드 역할에 대응하는 조직 타입을 반환합니다.
    private func organizationType(for role: ManagementTeam) -> OrganizationType {
        switch role {
        case .superAdmin,
                .centralPresident,
                .centralVicePresident,
                .centralOperatingTeamMember,
                .centralEducationTeamMember:
            return .central
        case .chapterPresident:
            return .chapter
        case .schoolPresident,
                .schoolVicePresident,
                .schoolPartLeader,
                .schoolEtcAdmin,
                .challenger:
            return .school
        }
    }
    #endif

    func seedAuthTokenFromEnvironmentIfNeeded() {
        #if DEBUG
        let environment = ProcessInfo.processInfo.environment
        let accessToken = environment["UMC_API_TEST_ACCESS_TOKEN"]?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !accessToken.isEmpty else { return }

        Task {
            do {
                try await KeychainTokenStore().save(
                    accessToken: accessToken,
                    refreshToken: accessToken
                )
                print("[AuthDebug] Seeded access token from scheme environment")
            } catch {
                print("[AuthDebug] Failed to seed access token: \(error)")
            }
        }
        #endif
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
                ) { granted, error in
                    #if DEBUG
                    if let error {
                        print("[Push] notification permission request failed: \(error)")
                    } else {
                        print("[Push] notification permission requested: granted=\(granted)")
                    }
                    #endif
                    guard granted else { return }
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            default:
                #if DEBUG
                print("[Push] notification permission not granted: \(settings.authorizationStatus.rawValue)")
                #endif
            }
        }
    }

    func logCurrentFCMToken() {
        guard Messaging.messaging().apnsToken != nil else {
            #if DEBUG
            print("[FCM] skip token fetch: APNS token not set yet")
            #endif
            return
        }
        Messaging.messaging().token { token, error in
            if let error {
                #if DEBUG
                print("[FCM] token fetch error: \(error)")
                #endif
                return
            }
            #if DEBUG
            print("[FCM] current token: \(token ?? "nil")")
            #endif
        }
    }
}
