//
//  FaieldVerificationUMC.swift
//  AppProduct
//
//  Created by euijjang97 on 1/13/26.
//

import SwiftUI

/// UMC 챌린저 인증 실패 화면
///
/// 회원가입 시 입력한 정보로 UMC 챌린저를 찾을 수 없을 때 표시되는 뷰입니다.
/// 사용자에게 UMC 공식 홈페이지 방문과 카카오톡 채널 문의 옵션을 제공합니다.
struct FailedVerificationUMC: View {

    // MARK: - Property

    /// 경고 아이콘 애니메이션 활성화 상태
    @State var showWarning: Bool = false

    /// URL을 외부 브라우저로 여는 환경 값
    @Environment(\.openURL) private var openURL
    @Environment(\.appFlow) private var appFlow
    @Environment(\.di) private var di

    /// 카카오톡 채널 연동 매니저
    let kakaoPlusManager: KakaoPlusManager = .init()

    /// 코드 입력 얼럿 표시 상태
    @State private var showCodeAlert: Bool = false
    /// 공통 알럿 프롬프트 상태
    @State private var alertPrompt: AlertPrompt?
    /// 전송 중 상태
    @State private var isSubmitting: Bool = false
    /// 입력된 챌린저 코드
    @State private var challengerCode: String = ""
    
    // MARK: - Constant

    /// 레이아웃 및 텍스트 상수
    private enum Constants {
        /// 상단 여백 높이
        static let spacerHeight: CGFloat = 80

        /// 메인 컴포넌트 간 수직 간격
        static let mianVspacing: CGFloat = 40

        /// 경고 아이콘 크기
        static let warningIconSize: CGFloat = 120

        /// 경고 아이콘 SF Symbol 이름
        static let warningIcon: String = "exclamationmark.triangle"

        /// 메인 타이틀 텍스트
        static let title: String = "UMC 챌린저 인증 실패"

        /// 서브타이틀 텍스트
        static let subTitle: String = "죄송합니다. 입력하신 정보로 등록된 \nUMC 챌린저 정보를 찾을 수 없습니다."

        /// 메인 버튼 텍스트
        static let mainBtnText: String = "UMC 공식 홈페이지 방문"
        /// 기존 챌린저 인증 버튼 텍스트
        static let verifyBtnText: String = "기존 챌린저 코드 입력"

        /// UMC 공식 홈페이지 URL
        static let homePageURL: String = "https://umc.it.kr"
    }
    
    var body: some View {
        VStack {
            Spacer().frame(maxHeight: Constants.spacerHeight)
            topWarningImage
            Spacer().frame(maxHeight: Constants.mianVspacing)
            warningTitle
            Spacer()
        }
        .safeAreaPadding(.horizontal, DefaultConstant.defaultSafeHorizon)
        .toolbar {
            ToolBarCollection.FailedVerificationBottomToolbar(
                isSubmitting: isSubmitting,
                onHome: {
                    if let url = URL(string: Constants.homePageURL) {
                        openURL(url)
                    }
                },
                onCode: {
                    showCodeAlert = true
                },
                onInquiry: {
                    kakaoPlusManager.openKakaoChannel()
                }
            )
        }
        .alert("기존 챌린저 코드 입력", isPresented: $showCodeAlert) {
            TextField("6자리 코드", text: $challengerCode)
                .keyboardType(.numberPad)
            Button("닫기", role: .cancel) {
                challengerCode = ""
            }
            Button("전송") {
                submitChallengerCode()
            }
        } message: {
            Text("운영진에게 발급받은 6자리 코드를 입력해주세요.")
        }
        .alertPrompt(item: $alertPrompt)
    }
    
    // MARK: - Top

    /// 상단 경고 아이콘
    ///
    /// 빨간색 삼각 경고 아이콘에 pulse 효과를 적용합니다.
    private var topWarningImage: some View {
        Image(systemName: Constants.warningIcon)
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: Constants.warningIconSize, height: Constants.warningIconSize)
            .foregroundStyle(.red)
            .symbolEffect(.pulse, isActive: showWarning)
            .task {
                showWarning.toggle()
            }
    }

    // MARK: - Middle

    /// 인증 실패 안내 문구
    ///
    /// 메인 타이틀과 서브타이틀로 구성된 텍스트 영역입니다.
    private var warningTitle: some View {
        VStack(spacing: DefaultSpacing.spacing16) {
            Text(Constants.title)
                .appFont(.title1Emphasis, color: .grey900)

            Text(Constants.subTitle)
                .appFont(.callout, weight: .medium, color: .grey600)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Private Function

    /// 기존 챌린저 인증 코드를 서버에 전송합니다.
    private func submitChallengerCode() {
        let trimmedCode = challengerCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let isDigitsOnly = trimmedCode.allSatisfy(\.isNumber)
        guard trimmedCode.count == 6, isDigitsOnly else {
            presentInvalidCodePrompt()
            return
        }

        isSubmitting = true
        Task {
            do {
                let useCase = di.resolve(AuthUseCaseProviding.self)
                    .registerExistingChallengerUseCase
                try await useCase.execute(code: trimmedCode)
                await MainActor.run {
                    isSubmitting = false
                    challengerCode = ""
                    presentSuccessPrompt()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    challengerCode = ""
                    presentInvalidCodePrompt()
                }
            }
        }
    }

    /// 인증 성공 안내 프롬프트를 표시합니다.
    private func presentSuccessPrompt() {
        alertPrompt = AlertPrompt(
            title: "인증 완료",
            message: "기존 챌린저로 인증되었습니다.",
            positiveBtnTitle: "확인",
            positiveBtnAction: {
                appFlow.showMain()
            }
        )
    }

    /// 인증 실패 안내 프롬프트를 표시합니다.
    private func presentInvalidCodePrompt() {
        alertPrompt = AlertPrompt(
            title: "인증 실패",
            message: "입력 코드 번호가 존재하지 않습니다.",
            positiveBtnTitle: "확인"
        )
    }
}

#Preview {
    FailedVerificationUMC()
}
