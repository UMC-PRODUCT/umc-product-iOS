//
//  LoginViewModel.swift
//  AppProduct
//
//  Created by euijjang97 on 1/12/26.
//

import Foundation

/// 로그인 화면의 상태 및 액션을 관리하는 ViewModel
@Observable
final class LoginViewModel {

    // MARK: - Property

    private let loginUseCase: LoginUseCaseProtocol
    private let kakaoLoginManager: KakaoLoginManager
    private let appleLoginManager: AppleLoginManager
    private let errorHandler: ErrorHandler

    /// 로그인 상태
    private(set) var loginState: Loadable<OAuthLoginResult> = .idle

    // MARK: - Init

    init(
        loginUseCase: LoginUseCaseProtocol,
        errorHandler: ErrorHandler,
        kakaoLoginManager: KakaoLoginManager = KakaoLoginManager(),
        appleLoginManager: AppleLoginManager = AppleLoginManager()
    ) {
        self.loginUseCase = loginUseCase
        self.errorHandler = errorHandler
        self.kakaoLoginManager = kakaoLoginManager
        self.appleLoginManager = appleLoginManager
    }

    // MARK: - Function

    /// 카카오 로그인 실행
    @MainActor
    func loginWithKakao() async {
        loginState = .loading

        do {
            let (accessToken, email) = try await kakaoLoginManager.login()
            #if DEBUG
            print("[Auth] 카카오 accessToken: \(accessToken)")
            print("[Auth] 카카오 email: \(email)")
            #endif
            let result = try await loginUseCase.executeKakao(
                accessToken: accessToken,
                email: email
            )
            #if DEBUG
            print("[Auth] 서버 로그인 결과: \(result)")
            #endif
            loginState = .loaded(result)
        } catch {
            loginState = .idle
            errorHandler.handle(error, context: ErrorContext(
                feature: "Auth",
                action: "loginWithKakao",
                retryAction: { [weak self] in
                    await self?.loginWithKakao()
                }
            ))
        }
    }

    /// Apple 로그인 실행
    @MainActor
    func loginWithApple() {
        loginState = .loading

        appleLoginManager.onAuthorizationCompleted = {
            [weak self] code, _, _ in
            guard let self else { return }
            Task { @MainActor in
                do {
                    let result = try await self.loginUseCase.executeApple(
                        authorizationCode: code
                    )
                    self.loginState = .loaded(result)
                } catch {
                    self.loginState = .idle
                    self.errorHandler.handle(
                        error,
                        context: ErrorContext(
                            feature: "Auth",
                            action: "loginWithApple",
                            retryAction: { [weak self] in
                                self?.loginWithApple()
                            }
                        )
                    )
                }
            }
        }

        appleLoginManager.signWithApple()
    }
}
