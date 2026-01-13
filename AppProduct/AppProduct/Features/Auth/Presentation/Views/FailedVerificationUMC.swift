//
//  FaieldVerificationUMC.swift
//  AppProduct
//
//  Created by euijjang97 on 1/13/26.
//

import SwiftUI

/// 회원가입 후 UMC 사람 아닐 경우 접근 금지 뷰
struct FailedVerificationUMC: View {
    
    // MARK: - Property
    @State var showWarning: Bool = false
    @Environment(\.openURL) private var openURL
    let kakaoPlusManager: KakaoPlusManager = .init()
    
    // MARK: - Constant
    private enum Constants {
        static let spacerHeight: CGFloat = 80
        static let mianVspacing: CGFloat = 40
        static let titleVspacing: CGFloat = 16
        static let warningIconSize: CGFloat = 120
        
        static let warningIcon: String = "exclamationmark.triangle"
        static let title: String = "UMC 챌린저 인증 실패"
        static let subTitle: String = "죄송합니다. 입력하신 정보로 등록된 \nUMC 챌린저 정보를 찾을 수 없습니다."
        static let mainBtnText: String = "UMC 공식 홈페이지 방문"
        static let inquriyText: String = "문의하기"
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
    /// 경고 문구
    private var warningTitle: some View {
        VStack(spacing: Constants.titleVspacing) {
            Text(Constants.title)
                .appFont(.title1Emphasis, color: .grey900)
            
            Text(Constants.subTitle)
                .appFont(.callout, color: .grey600)
        }
    }
    
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
