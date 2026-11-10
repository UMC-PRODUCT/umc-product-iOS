//
//  SocialLoginLabel.swift
//  CoreUIComponents
//
//  Created by euijjang97 on 5/27/26.
//

import CoreDesignSystem
import SwiftUI
import UMCFoundation

/// 로그인 버튼 라벨 (브랜드 컬러 캡슐)
///
/// 좌측 로고 + 중앙 정렬 텍스트로 구성된 풀-위드 캡슐 버튼 라벨.
/// 디자인 시스템 토큰만 사용하며, 색·문구·아이콘은 `LoginMethod`에서 주입된다.
public struct SocialLoginLabel: View {

    // MARK: - Property

    private let loginMethod: LoginMethod
    private let isLoading: Bool

    fileprivate enum Constants {
        static let leadingPadding: CGFloat = 16
        static let buttonHeight: CGFloat = 48
    }

    // MARK: - Init

    public init(_ loginMethod: LoginMethod, isLoading: Bool = false) {
        self.loginMethod = loginMethod
        self.isLoading = isLoading
    }

    public init(_ socialType: SocialType, isLoading: Bool = false) {
        self.init(.social(socialType), isLoading: isLoading)
    }

    // MARK: - Body

    public var body: some View {
        ZStack(alignment: .leading) {
            Text(isLoading ? "로그인 중…" : loginMethod.loginButtonTitle)
                .appFont(.callout, color: loginMethod.fontColor)
                .frame(maxWidth: .infinity)
                .frame(height: Constants.buttonHeight)
                .background(loginMethod.color, in: .capsule)

            loginLogo

            if isLoading {
                ProgressView()
                    .tint(loginMethod.fontColor)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, Constants.leadingPadding)
                    .accessibilityHidden(true)
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var loginLogo: some View {
        loginMethod.image
            .renderingMode(.original)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: loginMethod.iconSize, height: loginMethod.iconSize)
            .accessibilityHidden(true)
            .padding(.leading, Constants.leadingPadding)
    }
}

#if DEBUG
#Preview("SocialLoginLabel — 4종") {
    VStack(spacing: 12) {
        SocialLoginLabel(.kakao)
        SocialLoginLabel(.apple)
        SocialLoginLabel(.google)
        SocialLoginLabel(.email)
    }
    .padding()
}
#endif
