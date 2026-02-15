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

    /// 인증 상태 검사 완료 여부
    private(set) var isCheckComplete = false

    /// 스플래시 인증 판정 결과
    private(set) var authStatus: SplashAuthStatus = .notLoggedIn

    // MARK: - Init

    init(
        networkClient: NetworkClient,
        fetchMyProfileUseCase: FetchMyProfileUseCaseProtocol
    ) {
        self.networkClient = networkClient
        self.fetchMyProfileUseCase = fetchMyProfileUseCase
    }

    // MARK: - Function

    /// 인증 상태 검사
    ///
    /// 2초 대기와 토큰 검사를 동시에 실행합니다.
    @MainActor
    func checkAuthStatus() async {
        async let delay: Void = Task.sleep(for: .seconds(2))
        async let resolvedStatus = resolveAuthStatus()

        _ = try? await delay
        authStatus = await resolvedStatus
        isCheckComplete = true
    }

    // MARK: - Private Function

    /// 토큰/프로필 기반으로 스플래시 인증 상태를 판정합니다.
    private func resolveAuthStatus() async -> SplashAuthStatus {
        guard await networkClient.isLoggedIn() else {
            return .notLoggedIn
        }

        do {
            let profile = try await fetchMyProfileUseCase.execute()
            return profile.generations.isEmpty ? .pendingApproval : .approved
        } catch {
            // 토큰은 있으나 프로필 조회 실패 시 로그인 화면으로 안전하게 폴백
            return .notLoggedIn
        }
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
