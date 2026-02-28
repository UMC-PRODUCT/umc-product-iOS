//
//  AppProductApp.swift
//  AppProduct
//
//  Created by jaewon Lee on 12/30/25.
//

import CloudKit
import KakaoSDKAuth
import KakaoSDKCommon
import SwiftData
import SwiftUI

/// UMC 동아리 운영 관리 앱의 진입점
///
/// 앱 상태(splash/login/signUp/main)에 따라 루트 화면을 전환하고,
/// DIContainer, ErrorHandler, ModelContainer를 하위 뷰에 주입합니다.
@main
struct AppProductApp: App {
    
    // MARK: - Property
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var container: DIContainer
    @State private var didConfigureAppDelegate: Bool = false
    @State private var errorHandler: ErrorHandler = .init()
    @State private var appState: AppState = .splash
    private let sharedModelContainer: ModelContainer
    
    // MARK: - AppState
    
    /// 앱 전체 화면 상태
    private enum AppState: Equatable {
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
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            rootView
                .onOpenURL(perform: handleOpenURL)
                .environment(errorHandler)
                .environment(\.di, container)
                .environment(\.appFlow, appFlow)
                .modelContainer(sharedModelContainer)
                .onAppear(perform: configureAppDelegateIfNeeded)
                .onReceive(
                    NotificationCenter.default.publisher(for: .authSessionExpired)
                ) { _ in
                    handleAuthSessionExpired()
                }
                .onReceive(
                    NotificationCenter.default.publisher(for: .navigateToPendingApproval)
                ) { _ in
                    transition(to: .pendingApproval)
                }
        }
    }
}

// MARK: - Private Helpers

extension AppProductApp {
    @ViewBuilder
    private var rootView: some View {
        ZStack {
            switch appState {
            case .splash:
                SplashView(
                    networkClient: container.resolve(NetworkClient.self),
                    fetchMyProfileUseCase: container.resolve(
                        HomeUseCaseProviding.self
                    ).fetchMyProfileUseCase
                )
                .transition(rootTransition)

            case .login:
                LoginView(
                    loginUseCase: authProvider.loginUseCase,
                    fetchMyProfileUseCase: container.resolve(
                        HomeUseCaseProviding.self
                    ).fetchMyProfileUseCase,
                    errorHandler: errorHandler
                )
                .transition(rootTransition)

            case .signUp(let verificationToken):
                SignUpView(
                    oAuthVerificationToken: verificationToken,
                    sendEmailVerificationUseCase: authProvider
                        .sendEmailVerificationUseCase,
                    verifyEmailCodeUseCase: authProvider
                        .verifyEmailCodeUseCase,
                    registerUseCase: authProvider.registerUseCase,
                    fetchSignUpDataUseCase: authProvider.fetchSignUpDataUseCase
                )
                .transition(rootTransition)

            case .pendingApproval:
                FailedVerificationUMC()
                    .transition(rootTransition)

            case .main:
                UmcTab()
                    .transition(rootTransition)
            }
        }
        .animation(.easeInOut(duration: 0.28), value: appState)
    }
    
    /// Auth Feature의 UseCase Provider
    private var authProvider: AuthUseCaseProviding {
        container.resolve(AuthUseCaseProviding.self)
    }
    
    /// 앱 상태를 애니메이션과 함께 전환합니다.
    private func transition(to state: AppState) {
        guard state != appState else { return }
        withAnimation {
            appState = state
        }
    }

    /// 루트 화면 전환에 사용하는 공통 트랜지션
    private var rootTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .move(edge: .trailing)),
            removal: .opacity.combined(with: .move(edge: .leading))
        )
    }
    
    /// 카카오 로그인 딥링크 URL을 처리합니다.
    private func handleOpenURL(_ url: URL) {
        guard AuthApi.isKakaoTalkLoginUrl(url) else { return }
        _ = AuthController.handleOpenUrl(url: url)
    }
    
    /// AppDelegate 초기 설정을 1회만 수행합니다.
    private func configureAppDelegateIfNeeded() {
        guard !didConfigureAppDelegate else { return }
        didConfigureAppDelegate = true
        appDelegate.configure(
            container: container,
            modelContext: sharedModelContainer.mainContext
        )
    }
    
    /// 세션 만료 시 캐시 초기화 후 로그인 화면으로 전환합니다.
    private func handleAuthSessionExpired() {
        Task {
            try? await container.resolve(NetworkClient.self).logout()
        }
        container.resetCache()
        transition(to: .login)
    }

    /// 하위 뷰에서 앱 상태를 전환할 수 있도록 제공하는 AppFlow Environment 값
    private var appFlow: AppFlow {
        AppFlow(
            showLogin: { transition(to: .login) },
            showMain: { transition(to: .main) },
            showSignUp: { verificationToken in
                transition(to: .signUp(verificationToken: verificationToken))
            },
            showPendingApproval: { transition(to: .pendingApproval) },
            logout: { handleAuthSessionExpired() }
        )
    }
    
    /// SwiftData ModelContainer를 생성합니다.
    ///
    /// CloudKit 동기화를 시도하고, 실패 시 로컬 저장소로 폴백합니다.
    /// - Returns: 생성된 ModelContainer (CloudKit 또는 로컬)
    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([
            NoticeHistoryData.self,
            GenerationMappingRecord.self
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
                print("SwiftData local init failed. Fallback to in-memory store: \(error)")
                do {
                    let memoryConfiguration = ModelConfiguration(
                        schema: schema,
                        isStoredInMemoryOnly: true
                    )
                    return try ModelContainer(
                        for: schema,
                        configurations: [memoryConfiguration]
                    )
                } catch {
                    fatalError("Failed to initialize ModelContainer: \(error)")
                }
            }
        }
    }
}
