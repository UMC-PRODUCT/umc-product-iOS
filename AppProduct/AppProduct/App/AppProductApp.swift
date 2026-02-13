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
import CloudKit

@main
struct AppProductApp: App {
    @State private var container: DIContainer
    @State private var errorHandler: ErrorHandler = .init()
    @State private var appState: AppState = .main
    private let sharedModelContainer: ModelContainer

    // MARK: - ModelContainer

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
        sharedModelContainer = Self.makeModelContainer()
        KakaoSDK.initSDK(appKey: Config.kakaoAppKey)
        _container = State(
            initialValue: DIContainer.configured(
                modelContext: sharedModelContainer.mainContext
            )
        )
    }

    // MARK: - Factory
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
//                    UmcTab()
                    NavigationStack {
                        ScheduleDetailView(scheduleId: 1, selectedDate: .now)
                    }
                }
            }
            .onOpenURL { url in
                if AuthApi.isKakaoTalkLoginUrl(url) {
                    _ = AuthController.handleOpenUrl(url: url)
                }
            }
            .environment(errorHandler)
            .environment(\.di, container)
            .modelContainer(sharedModelContainer)
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

extension AppProductApp {

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([
            NoticeHistoryData.self,
            PenaltyRecord.self
        ])

        do {
            let cloudConfiguration = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: .automatic
            )
            return try ModelContainer(
                for: schema,
                configurations: [cloudConfiguration]
            )
        } catch {
            // CloudKit 설정/권한/모델 제약 이슈가 있으면 로컬 저장소로 폴백합니다.
            print("SwiftData CloudKit init failed. Fallback to local store: \(error)")

            do {
                let localConfiguration = ModelConfiguration(
                    schema: schema,
                    cloudKitDatabase: .none
                )
                return try ModelContainer(
                    for: schema,
                    configurations: [localConfiguration]
                )
            } catch {
                fatalError("Failed to initialize ModelContainer: \(error)")
            }
        }
    }

}
