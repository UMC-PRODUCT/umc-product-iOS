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

    /// 카카오톡 채널 연동 매니저
    let kakaoPlusManager: KakaoPlusManager = .init()
    
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

        /// 문의하기 버튼 텍스트
        static let inquriyText: String = "문의하기"

        /// UMC 공식 홈페이지 URL
        static let homePageURL: String = "https://umc.makeus.in"
    }
    
    var body: some View {
        VStack {
            Spacer().frame(maxHeight: Constants.spacerHeight)
            topWarningImage
            Spacer().frame(maxHeight: Constants.mianVspacing)
            warningTitle
            Spacer()
            MainButton(Constants.mainBtnText, action: {
                if let url = URL(string: Constants.homePageURL) {
                    openURL(url)
                }
            })
            .buttonStyle(.glassProminent)
            .tint(.indigo500)
        }
        .safeAreaPadding(.horizontal, DefaultConstant.defaultSafeHorizon)
        .safeAreaInset(edge: .bottom, content: {
            inquiryBtn
        })
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

    /// 문의하기 버튼
    ///
    /// 카카오톡 채널로 연결되는 텍스트 버튼입니다.
    private var inquiryBtn: some View {
        Button(action: {
            kakaoPlusManager.openKakaoChannel()
        }, label: {
            Text(Constants.inquriyText)
                .appFont(.callout, color: .grey700)
                .underline()
        })
    }
}

#Preview {
    FailedVerificationUMC()
}
