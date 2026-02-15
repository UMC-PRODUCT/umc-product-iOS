//
//  SplashView.swift
//  AppProduct
//
//  Created by euijjang97 on 1/12/26.
//

import SwiftUI

/// 스플래시 화면
///
/// 앱 시작 시 로고를 표시하며 토큰 검사를 수행합니다.
/// 검사 완료 시 `onComplete` 콜백으로 로그인 상태를 전달합니다.
struct SplashView: View {

    // MARK: - Property

    @State private var viewModel: SplashViewModel
    @Environment(\.appFlow) private var appFlow

    // MARK: - Init

    init(
        networkClient: NetworkClient,
        fetchMyProfileUseCase: FetchMyProfileUseCaseProtocol
    ) {
        self._viewModel = .init(
            wrappedValue: SplashViewModel(
                networkClient: networkClient,
                fetchMyProfileUseCase: fetchMyProfileUseCase
            )
        )
    }

    // MARK: - Body

    var body: some View {
        Logo()
            .task {
                await viewModel.checkAuthStatus()
            }
            .onChange(of: viewModel.isCheckComplete) { _, isComplete in
                if isComplete {
                    switch viewModel.authStatus {
                    case .approved:
                        appFlow.showMain()
                    case .pendingApproval:
                        appFlow.showPendingApproval()
                    case .notLoggedIn:
                        appFlow.showLogin()
                    }
                }
            }
    }
}
