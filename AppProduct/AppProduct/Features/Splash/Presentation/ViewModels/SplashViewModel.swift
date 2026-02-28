//
//  SplashViewModel.swift
//  AppProduct
//
//  Created by euijjang97 on 1/12/26.
//

import Foundation

/// 스플래시 화면의 상태를 관리하는 ViewModel
///
/// 앱 시작 시 2초간 스플래시를 표시하면서 토큰 검사를 수행합니다.
@Observable
final class SplashViewModel {

    // MARK: - Property

    private let networkClient: NetworkClient
    private let fetchMyProfileUseCase: FetchMyProfileUseCaseProtocol
    private let tokenStore: TokenStore

    /// 인증 상태 검사 완료 여부
    private(set) var isCheckComplete = false

    /// 스플래시 인증 판정 결과
    private(set) var authStatus: SplashAuthStatus = .notLoggedIn
    /// 디버그 표시용 액세스 토큰 문자열
    private(set) var debugAccessToken: String = "(nil)"
    /// 디버그 표시용 리프레시 토큰 문자열
    private(set) var debugRefreshToken: String = "(nil)"

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
    /// 2초 대기와 토큰 검사를 동시에 실행합니다.
    @MainActor
    func checkAuthStatus() async {
        await updateDebugTokens()
        async let delay: Void = Task.sleep(for: .seconds(2))
        async let resolvedStatus = resolveAuthStatus()

        _ = try? await delay
        authStatus = await resolvedStatus
        await updateDebugTokens()
        isCheckComplete = true
    }

    // MARK: - Private Function

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
