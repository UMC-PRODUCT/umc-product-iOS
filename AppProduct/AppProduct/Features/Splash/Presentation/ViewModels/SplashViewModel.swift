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

    /// 인증 상태 검사 완료 여부
    private(set) var isCheckComplete = false

    /// 로그인 상태 (토큰 존재 여부)
    private(set) var isLoggedIn = false

    // MARK: - Init

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    // MARK: - Function

    /// 인증 상태 검사
    ///
    /// 2초 대기와 토큰 검사를 동시에 실행합니다.
    @MainActor
    func checkAuthStatus() async {
        async let delay: Void = Task.sleep(for: .seconds(2))
        async let loggedIn = networkClient.isLoggedIn()

        _ = try? await delay
        isLoggedIn = await loggedIn
        isCheckComplete = true
    }
}
