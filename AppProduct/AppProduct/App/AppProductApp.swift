//
//  AppProductApp.swift
//  AppProduct
//
//  Created by jaewon Lee on 12/30/25.
//

import SwiftUI
import KakaoSDKCommon
import KakaoSDKAuth
import SwiftData

@main
struct AppProductApp: App {
    @State private var container: DIContainer = DIContainer.configured()
    @State private var errorHandler: ErrorHandler = .init()
    @State private var appState: AppState = .splash

    // MARK: - AppState

    /// 앱 전체 화면 상태
    private enum AppState {
        /// 스플래시 화면 (토큰 검사 중)
        case splash
        /// 로그인 화면
        case login
        /// 회원가입 화면
        case signUp(verificationToken: String)
        /// 승인 대기 화면
        case pendingApproval
        /// 메인 화면 (탭)
        case main
    }

    init() {
        KakaoSDK.initSDK(appKey: Config.kakaoAppKey)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                switch appState {
                case .splash:
                    SplashView(
                        networkClient: container.resolve(
                            NetworkClient.self
                        ),
                        onComplete: { isLoggedIn in
                            withAnimation {
                                appState = isLoggedIn ? .main : .login
                            }
                        }
                    )

                case .login:
                    let authProvider = container.resolve(
                        AuthUseCaseProviding.self
                    )
                    LoginView(
                        loginUseCase: authProvider.loginUseCase,
                        errorHandler: errorHandler,
                        onLoginSuccess: {
                            withAnimation {
                                appState = .main
                            }
                        },
                        onNewMember: { verificationToken in
                            withAnimation {
                                appState = .signUp(
                                    verificationToken: verificationToken
                                )
                            }
                        }
                    )

                case .signUp(let verificationToken):
                    let authProvider = container.resolve(
                        AuthUseCaseProviding.self
                    )
                    NavigationStack {
                        SignUpView(
                            oAuthVerificationToken: verificationToken,
                            sendEmailVerificationUseCase: authProvider
                                .sendEmailVerificationUseCase,
                            verifyEmailCodeUseCase: authProvider
                                .verifyEmailCodeUseCase,
                            registerUseCase: authProvider
                                .registerUseCase,
                            fetchSignUpDataUseCase: authProvider
                                .fetchSignUpDataUseCase,
                            onSignUpComplete: {
                                withAnimation {
                                    appState = .pendingApproval
                                }
                            }
                        )
                    }

                case .pendingApproval:
                    PendingApprovalView(
                        onRetryLogin: {
                            withAnimation {
                                appState = .login
                            }
                        }
                    )

                case .main:
                    UmcTab()
                }
            }
            .onOpenURL { url in
                if AuthApi.isKakaoTalkLoginUrl(url) {
                    _ = AuthController.handleOpenUrl(url: url)
                }
            }
            .environment(errorHandler)
            .environment(\.di, container)
            .modelContainer(for: NoticeHistoryData.self)
            .onReceive(
                NotificationCenter.default.publisher(
                    for: .authSessionExpired
                )
            ) { _ in
                Task {
                    try? await container.resolve(
                        NetworkClient.self
                    ).logout()
                }
                container.resetCache()
                withAnimation {
                    appState = .login
                }
            }
        }
    }
}
