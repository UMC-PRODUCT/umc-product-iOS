//
//  LoginView.swift
//  AppProduct
//
//  Created by euijjang97 on 1/12/26.
//

import SwiftUI

/// 로그인 화면
///
/// UMC 앱의 진입점으로, 소셜 로그인 버튼을 제공합니다.
/// 중앙에 로고와 설명을 배치하고, 하단에 소셜 로그인 옵션을 표시합니다.
struct LoginView: View {

    // MARK: - Property

    /// 로그인 뷰 모델 (@Observable 패턴)
    @State private var viewModel: LoginViewModel
    @Environment(\.appFlow) private var appFlow

    // MARK: - Init

    init(
        loginUseCase: LoginUseCaseProtocol,
        errorHandler: ErrorHandler
    ) {
        self._viewModel = .init(
            wrappedValue: LoginViewModel(
                loginUseCase: loginUseCase,
                errorHandler: errorHandler
            )
        )
    }

    // MARK: - Body

    var body: some View {
        VStack {
            Spacer()
            TopLogo()
            Spacer()
            BottomSocialBtns(
                isLoading: viewModel.loginState.isLoading,
                onKakaoTapped: {
                    Task { await viewModel.loginWithKakao() }
                },
                onAppleTapped: {
                    viewModel.loginWithApple()
                }
            )
        }
        .onChange(of: viewModel.loginState) { _, newState in
            if case .loaded(let result) = newState {
                switch result {
                case .existingMember:
                    appFlow.showMain()
                case .newMember(let verificationToken):
                    appFlow.showSignUp(verificationToken)
                }
            }
        }
    }
}

// MARK: - TopLogo

/// 상단 로고 영역 (Presenter 패턴)
///
/// UMC 로고와 설명 텍스트를 세로로 배치합니다.
/// Equatable 준수로 불필요한 렌더링을 방지합니다.
fileprivate struct TopLogo: View, Equatable {

    // MARK: - Constant

    /// 레이아웃 및 텍스트 상수
    private enum Constants {
        /// 로고 설명 문구
        static let logoDescrip: String = "UMC 활동을 더 편하게 관리해보세요"
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: DefaultSpacing.spacing4, content: {
            Logo()
            Text(Constants.logoDescrip)
                .appFont(.body, weight: .medium, color: .grey600)
        })
    }
}

// MARK: - BottomSocialBtns

/// 하단 소셜 로그인 버튼 영역
fileprivate struct BottomSocialBtns: View {

    // MARK: - Constant

    /// 레이아웃 상수
    private enum Constants {
        /// 소셜 버튼 간 수직 간격
        static let btnSpacing: CGFloat = 16
    }

    // MARK: - Property

    let isLoading: Bool
    var onKakaoTapped: () -> Void
    var onAppleTapped: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: Constants.btnSpacing) {
            ForEach(SocialType.allCases, id: \.self) { btn in
                Button(action: {
                    switch btn {
                    case .kakao:
                        onKakaoTapped()
                    case .apple:
                        onAppleTapped()
                    }
                }, label: {
                    btn.image
                })
                .glassEffect(.regular.interactive())
                .disabled(isLoading)
            }

            if isLoading {
                ProgressView()
                    .padding(.top, DefaultSpacing.spacing8)
            }
        }
    }
}
