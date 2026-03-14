//
//  SplashViewModel.swift
//  AppProduct
//
//  Created by euijjang97 on 1/12/26.
//

import Foundation
import UIKit

/// 스플래시 화면의 상태를 관리하는 ViewModel
///
/// 앱 시작 시 2초간 스플래시를 표시하면서 앱 버전 검사 및 토큰 검사를 수행합니다.
@Observable
final class SplashViewModel {

    // MARK: - Property

    private let networkClient: NetworkClient
    private let fetchMyProfileUseCase: FetchMyProfileUseCaseProtocol
    private let tokenStore: TokenStore

    /// 인증 상태 검사 완료 여부
    private(set) var isCheckComplete = false

    /// 앱 업데이트 필요 여부
    private(set) var needsUpdate = false

    /// 강제 업데이트 Alert
    var updateAlertPrompt: AlertPrompt?

    /// 스플래시 인증 판정 결과
    private(set) var authStatus: SplashAuthStatus = .notLoggedIn
    /// 디버그 표시용 액세스 토큰 문자열
    private(set) var debugAccessToken: String = "(nil)"
    /// 디버그 표시용 리프레시 토큰 문자열
    private(set) var debugRefreshToken: String = "(nil)"

    fileprivate enum Constants {
        static let appStoreID = "6759412446"
        static let lookupURLString = "https://itunes.apple.com/lookup?bundleId=com.umc.product&country=kr"
        static let appStoreURLString = "https://apps.apple.com/us/app/umc/id\(appStoreID)"
    }

    // MARK: - Init

    init(
        networkClient: NetworkClient,
        fetchMyProfileUseCase: FetchMyProfileUseCaseProtocol,
        tokenStore: TokenStore
    ) {
        self.networkClient = networkClient
        self.fetchMyProfileUseCase = fetchMyProfileUseCase
        self.tokenStore = tokenStore
    }

    // MARK: - Function

    /// 인증 상태 검사
    ///
    /// 2초 대기, 앱 버전 검사, 토큰 검사를 동시에 실행합니다.
    /// 앱 업데이트가 필요한 경우 인증 검사를 완료하지 않고 업데이트 Alert를 표시합니다.
    @MainActor
    func checkAuthStatus() async {
        await updateDebugTokens()
        async let delay: Void = Task.sleep(for: .seconds(2))
        async let updateRequired = checkAppStoreVersion()
        async let resolvedStatus = resolveAuthStatus()

        _ = try? await delay

        if await updateRequired {
            needsUpdate = true
            showUpdateAlert()
            return
        }

        authStatus = await resolvedStatus
        await updateDebugTokens()
        isCheckComplete = true
    }

    /// 강제 업데이트 Alert를 표시합니다.
    ///
    /// App Store에서 돌아왔을 때 다시 표시하기 위해 별도 메서드로 분리합니다.
    func showUpdateAlert() {
        updateAlertPrompt = AlertPrompt(
            title: "업데이트 안내",
            message: "새로운 버전이 출시되었습니다.\n최신 버전으로 업데이트해주세요.",
            positiveBtnTitle: "업데이트",
            positiveBtnAction: { [weak self] in
                self?.openAppStore()
            }
        )
    }

    /// App Store로 이동합니다.
    private func openAppStore() {
        guard let url = URL(string: Constants.appStoreURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Private Function

    /// App Store Lookup API를 호출하여 업데이트가 필요한지 확인합니다.
    ///
    /// App Store 버전이 현재 앱 버전보다 높으면 `true`를 반환합니다.
    /// API 호출 실패 시에는 `false`를 반환하여 앱 진입을 차단하지 않습니다.
    private func checkAppStoreVersion() async -> Bool {
        guard let url = URL(string: Constants.lookupURLString) else {
            return false
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let result = try JSONDecoder().decode(
                AppStoreLookupResult.self,
                from: data
            )
            guard let storeVersion = result.results.first?.version else {
                return false
            }
            let currentVersion = Bundle.main.infoDictionary?[
                "CFBundleShortVersionString"
            ] as? String ?? "0.0.0"

            return storeVersion.compare(
                currentVersion,
                options: .numeric
            ) == .orderedDescending
        } catch {
            return false
        }
    }

    /// 토큰/프로필 기반으로 스플래시 인증 상태를 판정합니다.
    private func resolveAuthStatus() async -> SplashAuthStatus {
        let defaults = UserDefaults.standard
        let canAutoLogin = defaults.bool(
            forKey: AppStorageKey.canAutoLogin
        )
        let hasAccessToken = await networkClient.isLoggedIn()

        guard hasAccessToken else {
            return .notLoggedIn
        }

        // HomeDebug 스킴: 환경변수로 토큰 갱신 스킵
        let skipRefresh = ProcessInfo.processInfo
            .environment["SKIP_TOKEN_REFRESH"] != nil

        if !skipRefresh {
            // 앱 시작 시 토큰을 선행 갱신하여 이후 API 실패 가능성을 줄입니다.
            do {
                _ = try await networkClient.forceRefreshToken()
            } catch {
                // 리프레시 실패 시에도 액세스 토큰으로 프로필 조회를 한 번 더 시도합니다.
            }
        }

        do {
            let profile = try await fetchMyProfileUseCase.execute()
            let isApproved = isApprovedProfile(profile)
            if isApproved {
                if !canAutoLogin {
                    defaults.set(true, forKey: AppStorageKey.canAutoLogin)
                }
                return .approved
            }
            return canAutoLogin ? .pendingApproval : .notLoggedIn
        } catch {
            // 토큰은 있으나 프로필 조회 실패 시 로그인 화면으로 안전하게 폴백
            if canAutoLogin {
                try? await networkClient.logout()
            }
            return .notLoggedIn
        }
    }

    func isApprovedProfile(_ profile: HomeProfileResult) -> Bool {
        if !profile.generations.isEmpty {
            return true
        }

        for seasonType in profile.seasonTypes {
            if case .gens(let generations) = seasonType, !generations.isEmpty {
                return true
            }
        }

        return false
    }

    @MainActor
    func updateDebugTokens() async {
        debugAccessToken = await tokenStore.getAccessToken() ?? "(nil)"
        debugRefreshToken = await tokenStore.getRefreshToken() ?? "(nil)"
    }
}

// MARK: - SplashAuthStatus

/// 스플래시 인증 판정 상태
enum SplashAuthStatus {
    /// 정상 로그인 + 승인 완료
    case approved
    /// 토큰은 있으나 승인 대기 상태
    case pendingApproval
    /// 로그아웃 상태 혹은 인증 판정 실패
    case notLoggedIn
}

// MARK: - AppStoreLookupResult

/// App Store Lookup API 응답 모델
private struct AppStoreLookupResult: Decodable {
    let resultCount: Int
    let results: [AppStoreAppInfo]
}

/// App Store 앱 정보
private struct AppStoreAppInfo: Decodable {
    let version: String
}
